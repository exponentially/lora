defmodule LoraWeb.LobbyLive do
  use LoraWeb, :live_view

  require Logger

  @impl true
  @spec mount(any(), map(), Phoenix.LiveView.Socket.t()) ::
          {:ok, map(), [{:temporary_assigns, [...]}, ...]}
  def mount(_params, _session, socket) do
    # At this point, LiveAuth hook has already assigned :current_player
    player_id = if socket.assigns.current_player, do: socket.assigns.current_player.sub, else: nil

    player_name =
      if socket.assigns.current_player, do: socket.assigns.current_player.name, else: ""

    # Get open games list
    open_games = Lora.list_open_games() |> Enum.sort_by(& &1.created_at, :desc)

    # Get player's active games if logged in
    active_games =
      if player_id do
        Lora.list_player_active_games(player_id) |> Enum.sort_by(& &1.last_activity, :desc)
      else
        []
      end

    socket =
      socket
      |> assign(:player_id, player_id)
      |> assign(:player_name, player_name)
      |> assign(:game_code, "")
      |> assign(:error_message, nil)
      |> assign(:open_games, open_games)
      |> assign(:active_games, active_games)

    if connected?(socket), do: Process.send_after(self(), :update_games, 10000)

    {:ok, socket, temporary_assigns: [error_message: nil]}
  end

  @impl true
  def handle_info(:update_games, socket) do
    player_id = if socket.assigns.current_player, do: socket.assigns.current_player.sub, else: nil

    # Get updated game lists
    open_games = Lora.list_open_games() |> Enum.sort_by(& &1.created_at, :desc)

    active_games =
      if player_id do
        Lora.list_player_active_games(player_id) |> Enum.sort_by(& &1.last_activity, :desc)
      else
        []
      end

    socket =
      socket
      |> assign(:open_games, open_games)
      |> assign(:active_games, active_games)

    Process.send_after(self(), :update_games, 10000)

    {:noreply, socket}
  end

  @impl true
  def handle_event("create_game", params, socket) do
    IO.puts("CREATE GAME CALLED with params: #{inspect(params)}")
    IO.puts("Full socket assigns: #{inspect(socket.assigns)}")

    current_player = Map.get(socket.assigns, :current_player)
    IO.puts("Current player extracted: #{inspect(current_player)}")

    cond do
      is_nil(current_player) ->
        # Redirect to Auth0 login with state parameter for game creation
        state = URI.encode_www_form("/lobby#create")
        IO.puts("No current player, redirecting to Auth0 with state: #{state}")
        {:noreply, redirect(socket, to: "/auth/auth0?state=#{state}")}

      is_map(current_player) && Map.has_key?(current_player, :sub) &&
          Map.has_key?(current_player, :name) ->
        player_id = current_player.sub
        name = current_player.name

        IO.puts("Attempting to create game for player: #{player_id}, #{name}")

        case Lora.create_game(player_id, name) do
          {:ok, game_id} ->
            IO.puts("Game created successfully with ID: #{game_id}")
            {:noreply, redirect_to_game(socket, game_id, name)}

          {:error, reason} ->
            IO.puts("Game creation failed: #{reason}")
            {:noreply, assign(socket, error_message: "Failed to create game: #{reason}")}
        end

      true ->
        # Handle case where current_player is defined but incomplete
        IO.puts("Invalid current_player data structure: #{inspect(current_player)}")

        {:noreply,
         assign(socket,
           error_message: "Authentication data is invalid. Please try logging in again."
         )}
    end
  end

  @impl true
  def handle_event(
        "join_game",
        %{"join_game" => %{"game_code" => game_code}},
        socket
      ) do
    game_code = String.trim(game_code)

    cond do
      not valid_game_code?(game_code) ->
        {:noreply, assign(socket, error_message: "Please enter a valid game code (6 characters)")}

      not Lora.game_exists?(game_code) ->
        {:noreply, assign(socket, error_message: "Game not found")}

      socket.assigns.current_player ->
        # User is authenticated, proceed with joining
        player_id = socket.assigns.current_player.sub
        name = socket.assigns.current_player.name

        case Lora.join_game(game_code, player_id, name) do
          {:ok, _game} ->
            {:noreply, redirect_to_game(socket, game_code, name)}

          {:error, reason} ->
            {:noreply, assign(socket, error_message: reason)}
        end

      true ->
        # Redirect to Auth0 login with state parameter for joining this game
        state = URI.encode_www_form("/game/#{game_code}")
        {:noreply, redirect(socket, to: "/auth/auth0?state=#{state}")}
    end
  end

  @impl true
  def handle_event("validate", %{"create_player" => params}, socket) do
    socket =
      socket
      |> assign(:player_name, Map.get(params, "name", ""))

    {:noreply, socket}
  end

  @impl true
  def handle_event("validate", %{"join_player" => params}, socket) do
    socket =
      socket
      |> assign(:player_name, Map.get(params, "name", ""))
      |> assign(:game_code, Map.get(params, "game_code", ""))

    {:noreply, socket}
  end

  # Helper functions

  defp valid_game_code?(code) do
    String.length(String.trim(code)) == 6
  end

  defp redirect_to_game(socket, game_id, player_name) do
    socket =
      socket
      |> assign(:game_id, game_id)
      |> assign(:player_name, player_name)

    push_navigate(socket, to: ~p"/game/#{game_id}", replace: false)
  end

  def time_ago(datetime) do
    # Ensure we're working with DateTime structs
    datetime =
      case datetime do
        %DateTime{} ->
          datetime

        %NaiveDateTime{} ->
          DateTime.from_naive!(datetime, "Etc/UTC")

        _ ->
          # If it's something else, default to now
          DateTime.utc_now()
      end

    diff = DateTime.diff(DateTime.utc_now(), datetime)

    cond do
      diff < 60 -> "just now"
      diff < 3600 -> "#{div(diff, 60)} minutes ago"
      diff < 86400 -> "#{div(diff, 3600)} hours ago"
      diff < 2_592_000 -> "#{div(diff, 86400)} days ago"
      true -> Calendar.strftime(datetime, "%Y-%m-%d")
    end
  end
end
