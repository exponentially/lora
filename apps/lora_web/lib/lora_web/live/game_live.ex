defmodule LoraWeb.GameLive do
  use LoraWeb, :live_view
  require Logger

  alias Phoenix.PubSub
  alias Lora.{Contract}

  @impl true
  def mount(%{"id" => game_id}, session, socket) do
    player_id =  Map.fetch!(session, "player_id")
    player_name = session["player_name"] || player_id

    if is_nil(player_id) do
      Logger.error("Missing player information in session or socket assigns")
      {:ok, redirect_to_lobby(socket, "Missing player information")}
    else
      if connected?(socket) do
        # Subscribe to game updates
        PubSub.subscribe(Lora.PubSub, "game:#{game_id}")

        case Lora.get_game_state(game_id) do
          {:ok, game} ->
            # For reconnection, inform the server of the new pid
            if Enum.any?(game.players, fn p -> p.id == player_id end) do
              Lora.player_reconnect(game_id, player_id, self())
            else
              # For new joins, add the player to the game
              case Lora.add_player(game_id, player_id, player_name) do
                {:ok, updated_game} ->
                  socket = assign_game_state(socket, updated_game, player_id)
                  {:ok, socket}

                {:error, reason} ->
                  {:ok, redirect_to_lobby(socket, reason)}
              end
            end

            socket = assign_game_state(socket, game, player_id)
            {:ok, socket}

          _ ->
            {:ok, redirect_to_lobby(socket, "Game not found")}
        end
      else
        socket =
          socket
          |> assign(:game_id, game_id)
          |> assign(:player_id, player_id)
          |> assign(:player_name, player_name)
          |> assign(:loading, true)

        {:ok, socket}
      end
    end
  end

  @impl true
  def handle_event("play_card", %{"suit" => suit, "rank" => rank}, socket) do
    game_id = socket.assigns.game_id
    player_id = socket.assigns.player_id

    # Convert the string values to atoms/integers for the card
    suit = String.to_existing_atom(suit)
    rank = convert_rank(rank)
    card = {suit, rank}

    case Lora.play_card(game_id, player_id, card) do
      {:ok, _updated_game} ->
        {:noreply, socket}

      {:error, reason} ->
        # Use put_flash from Phoenix.LiveView
        {:noreply, Phoenix.LiveView.put_flash(socket, :error, reason)}
    end
  end

  @impl true
  def handle_event("pass", _params, socket) do
    game_id = socket.assigns.game_id
    player_id = socket.assigns.player_id

    case Lora.pass_lora(game_id, player_id) do
      {:ok, _updated_game} ->
        {:noreply, socket}

      {:error, reason} ->
        # Use put_flash from Phoenix.LiveView
        {:noreply, Phoenix.LiveView.put_flash(socket, :error, reason)}
    end
  end

  @impl true
  def handle_info({:game_state, game}, socket) do
    player_id = Map.get(socket.assigns, :player_id)
    socket = assign_game_state(socket, game, player_id)
    {:noreply, socket}
  end

  @impl true
  def handle_info({event_type, _payload}, socket) when event_type in [:card_played, :player_passed, :player_joined, :player_disconnected, :player_reconnected, :game_started, :game_over, :player_timeout] do
    # Handle various game events if needed
    # For now, these events are just for information and don't require specific handling
    {:noreply, socket}
  end

  @impl true
  def terminate(_reason, socket) do
    if connected?(socket) and Map.has_key?(socket.assigns, :game_id) and Map.has_key?(socket.assigns, :player_id) do
      # Only disconnect from game if we have valid game_id and player_id
      Lora.player_disconnect(socket.assigns.game_id, socket.assigns.player_id)
    end

    :ok
  end

  # Helper functions

  defp assign_game_state(socket, game, player_id) do
    # Find the player's seat
    player = Enum.find(game.players, fn p -> p.id == player_id end)

    socket
    |> assign(:game, game)
    |> assign(:loading, false)
    |> assign(:player, player)
    |> assign(:current_contract, Contract.at(game.contract_index))
    |> assign(:legal_moves, get_legal_moves(game, player))
  end

  defp get_legal_moves(_game, nil), do: []
  defp get_legal_moves(game, player) do
    if game.phase == :playing and game.current_player == player.seat do
      {:ok, legal_cards} = Lora.legal_moves(game.id, player.id)
      legal_cards
    else
      []
    end
  end

  defp convert_rank(rank) do
    case rank do
      "ace" -> :ace
      "king" -> :king
      "queen" -> :queen
      "jack" -> :jack
      number -> String.to_integer(number)
    end
  end

  defp redirect_to_lobby(socket, flash_message) do
    socket
    |> put_flash(:error, flash_message)
    |> push_navigate(to: ~p"/")
  end

  # View helper functions

  def find_player_name(game, seat) do
    game.players
    |> Enum.find(fn p -> p.seat == seat end)
    |> case do
      nil -> "Unknown"
      player -> player.name
    end
  end

  def format_suit(suit) do
    case suit do
      :hearts -> "♥"
      :diamonds -> "♦"
      :clubs -> "♣"
      :spades -> "♠"
      _ -> suit
    end
  end

  def format_rank(rank) do
    case rank do
      :ace -> "A"
      :king -> "K"
      :queen -> "Q"
      :jack -> "J"
      num -> num
    end
  end

  def suit_color(suit) when suit in [:hearts, :diamonds], do: "hearts"  # red
  def suit_color(suit) when suit in [:clubs, :spades], do: "clubs"  # black

  def find_winner(scores) do
    {winning_seat, _} = Enum.max_by(scores, fn {_seat, score} -> score end)
    winning_seat
  end
end
