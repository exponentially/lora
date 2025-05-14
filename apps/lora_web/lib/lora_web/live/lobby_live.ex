defmodule LoraWeb.LobbyLive do
  use LoraWeb, :live_view

  require Logger

  @impl true
  @spec mount(any(), map(), Phoenix.LiveView.Socket.t()) ::
          {:ok, map(), [{:temporary_assigns, [...]}, ...]}
  def mount(_params, session, socket) do
    # Generate a unique player ID if not already present in session
    player_id = Map.fetch!(session, "player_id")

    socket =
      socket
      |> assign(:player_id, player_id)
      |> assign(:player_name, "")
      |> assign(:game_code, "")
      |> assign(:error_message, nil)

    # Store player_id in session
    {:ok, socket, temporary_assigns: [error_message: nil]}
  end

  @impl true
  def handle_event("create_game", %{"create_player" => %{"name" => name}}, socket) do
    if valid_name?(name) do
      player_id = socket.assigns.player_id

      case Lora.create_game(player_id, name) do
        {:ok, game_id} ->
          {:noreply, redirect_to_game(socket, game_id, name)}

        {:error, reason} ->
          {:noreply, assign(socket, error_message: "Failed to create game: #{reason}")}
      end
    else
      {:noreply, assign(socket, error_message: "Please enter a valid name (3-20 characters)")}
    end
  end

  @impl true
  def handle_event(
        "join_game",
        %{"join_player" => %{"name" => name, "game_code" => game_code}},
        socket
      ) do
    game_code = String.trim(game_code)
    player_id = socket.assigns.player_id

    cond do
      not valid_name?(name) ->
        {:noreply, assign(socket, error_message: "Please enter a valid name (3-20 characters)")}

      not valid_game_code?(game_code) ->
        {:noreply, assign(socket, error_message: "Please enter a valid game code (6 characters)")}

      not Lora.game_exists?(game_code) ->
        {:noreply, assign(socket, error_message: "Game not found")}

      true ->
        case Lora.join_game(game_code, player_id, name) do
          {:ok, _game} ->
            {:noreply, redirect_to_game(socket, game_code, name)}

          {:error, reason} ->
            {:noreply, assign(socket, error_message: reason)}
        end
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

  defp valid_name?(name) do
    String.length(String.trim(name)) >= 3 && String.length(String.trim(name)) <= 20
  end

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
end
