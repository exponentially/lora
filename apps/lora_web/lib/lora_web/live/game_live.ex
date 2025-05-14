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
    # Access the game ID from socket.assigns.game.id instead of game_id
    game_id = socket.assigns.game.id
    player_id = socket.assigns.player.id

    # Convert the string values to atoms/integers for the card
    suit = String.to_existing_atom(suit)
    rank = convert_rank(rank)
    card = {suit, rank}

    case Lora.play_card(game_id, player_id, card) do
      {:ok, _updated_game} ->
        Logger.debug("Card played successfully: #{inspect(card)}")
        {:noreply, socket}

      {:error, reason} ->
        Logger.error("Error playing card: #{reason}")  # Log the error reason
        # Use put_flash from Phoenix.LiveView
        {:noreply, Phoenix.LiveView.put_flash(socket, :error, reason)}
    end
  end

  @impl true
  def handle_event("pass", _params, socket) do
    # Access the game ID and player ID from the nested structure
    game_id = socket.assigns.game.id
    player_id = socket.assigns.player.id

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
    # Use more robust player ID retrieval that works in both initial and connected states
    player_id = cond do
      # If we have player object in assigns, get ID from there
      Map.has_key?(socket.assigns, :player) && is_map(socket.assigns.player) ->
        socket.assigns.player.id
      # Fallback to direct player_id in assigns
      Map.has_key?(socket.assigns, :player_id) ->
        socket.assigns.player_id
      true ->
        nil
    end

    if player_id do
      socket = assign_game_state(socket, game, player_id)
      {:noreply, socket}
    else
      Logger.error("Player ID not found in socket assigns during game update")
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({event_type, _payload}, socket) when event_type in [:card_played, :player_passed, :player_joined, :player_disconnected, :player_reconnected, :game_started, :game_over, :player_timeout] do
    # Handle various game events if needed
    # For now, these events are just for information and don't require specific handling
    {:noreply, socket}
  end

  @impl true
  def terminate(_reason, socket) do
    # Use more robust checking to account for different states of the socket assigns
    cond do
      # First check if we have game and player directly in the assigns structure
      connected?(socket) and Map.has_key?(socket.assigns, :game) and is_map(socket.assigns.game) and
      Map.has_key?(socket.assigns, :player) and is_map(socket.assigns.player) ->
        Lora.player_disconnect(socket.assigns.game.id, socket.assigns.player.id)

      # Fallback to the original approach for backward compatibility
      connected?(socket) and Map.has_key?(socket.assigns, :game_id) and Map.has_key?(socket.assigns, :player_id) ->
        Lora.player_disconnect(socket.assigns.game_id, socket.assigns.player_id)

      true -> :ok
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
