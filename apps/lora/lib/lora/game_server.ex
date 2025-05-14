defmodule Lora.GameServer do
  @moduledoc """
  GenServer implementation for managing Lora game state.
  Each game instance is a separate GenServer process.
  """

  use GenServer
  require Logger

  alias Lora.Game
  alias Phoenix.PubSub

  @reconnect_timeout 30_000  # 30 seconds

  # Client API

  @doc """
  Starts a new game server with the given ID.
  """
  def start_link(game_id) do
    GenServer.start_link(__MODULE__, game_id, name: via_tuple(game_id))
  end

  @doc """
  Returns the state of the game.
  """
  def get_state(game_id) do
    GenServer.call(via_tuple(game_id), :get_state)
  end

  @doc """
  Adds a player to the game.
  """
  def add_player(game_id, player_id, player_name) do
    GenServer.call(via_tuple(game_id), {:add_player, player_id, player_name})
  end

  @doc """
  Plays a card from a player's hand.
  """
  def play_card(game_id, player_id, card) do
    GenServer.call(via_tuple(game_id), {:play_card, player_id, card})
  end

  @doc """
  Passes in the Lora contract when a player has no legal moves.
  """
  def pass_lora(game_id, player_id) do
    GenServer.call(via_tuple(game_id), {:pass_lora, player_id})
  end

  @doc """
  Handles a player reconnection.
  """
  def player_reconnect(game_id, player_id, pid) do
    GenServer.call(via_tuple(game_id), {:player_reconnect, player_id, pid})
  end

  @doc """
  Handles a player disconnection.
  """
  def player_disconnect(game_id, player_id) do
    GenServer.cast(via_tuple(game_id), {:player_disconnect, player_id})
  end

  @doc """
  Returns legal moves for the current player.
  """
  def legal_moves(game_id, player_id) do
    GenServer.call(via_tuple(game_id), {:legal_moves, player_id})
  end

  # Helper for registry lookup
  defp via_tuple(game_id) do
    {:via, Registry, {Lora.GameRegistry, game_id}}
  end

  # Server callbacks

  @impl true
  def init(game_id) do
    Logger.info("Starting game server for game #{game_id}")

    # Initialize game state
    state = %{
      game: Game.new_game(game_id),
      player_pids: %{},
      disconnected_players: %{},
      timers: %{}
    }

    {:ok, state}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, {:ok, state.game}, state}
  end

  @impl true
  def handle_call({:add_player, player_id, player_name}, {pid, _}, state) do
    case Game.add_player(state.game, player_id, player_name) do
      {:ok, updated_game} ->
        # Add player's pid to the map
        updated_pids = Map.put(state.player_pids, player_id, pid)

        # Broadcast the new state
        broadcast_state(updated_game)

        # Start the game if now we have 4 players
        if length(updated_game.players) == 4 do
          broadcast_event(updated_game.id, :game_started, %{})
        else
          broadcast_event(updated_game.id, :player_joined, %{player: player_name, seat: length(updated_game.players)})
        end

        {:reply, {:ok, updated_game}, %{state | game: updated_game, player_pids: updated_pids}}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call({:play_card, player_id, card}, _from, state) do
    game = state.game

    # Find player's seat
    case find_player_seat(game, player_id) do
      nil ->
        {:reply, {:error, "Player not in game"}, state}

      seat ->
        case Game.play_card(game, seat, card) do
          {:ok, updated_game} ->
            # Broadcast the new state and card played event
            broadcast_state(updated_game)
            broadcast_event(
              updated_game.id,
              :card_played,
              %{
                player_id: player_id,
                seat: seat,
                card: card
              }
            )

            # If the phase changed to finished, broadcast game over
            if updated_game.phase == :finished and game.phase != :finished do
              broadcast_event(updated_game.id, :game_over, %{scores: updated_game.scores})
            end

            {:reply, {:ok, updated_game}, %{state | game: updated_game}}

          {:error, reason} ->
            {:reply, {:error, reason}, state}
        end
    end
  end

  @impl true
  def handle_call({:pass_lora, player_id}, _from, state) do
    game = state.game

    # Find player's seat
    case find_player_seat(game, player_id) do
      nil ->
        {:reply, {:error, "Player not in game"}, state}

      seat ->
        case Game.pass_lora(game, seat) do
          {:ok, updated_game} ->
            # Broadcast the new state and pass event
            broadcast_state(updated_game)
            broadcast_event(
              updated_game.id,
              :player_passed,
              %{
                player_id: player_id,
                seat: seat
              }
            )

            {:reply, {:ok, updated_game}, %{state | game: updated_game}}

          {:error, reason} ->
            {:reply, {:error, reason}, state}
        end
    end
  end

  @impl true
  def handle_call({:player_reconnect, player_id, pid}, _from, state) do
    if Map.has_key?(state.disconnected_players, player_id) do
      # Cancel disconnect timer if it exists
      timer = state.timers[player_id]
      if timer, do: Process.cancel_timer(timer)

      # Update state to show player as reconnected
      updated_pids = Map.put(state.player_pids, player_id, pid)
      updated_disconnected = Map.delete(state.disconnected_players, player_id)
      updated_timers = Map.delete(state.timers, player_id)

      broadcast_event(state.game.id, :player_reconnected, %{player_id: player_id})

      {:reply, {:ok, state.game}, %{state |
        player_pids: updated_pids,
        disconnected_players: updated_disconnected,
        timers: updated_timers
      }}
    else
      # Player wasn't disconnected, just update their PID
      updated_pids = Map.put(state.player_pids, player_id, pid)
      {:reply, {:ok, state.game}, %{state | player_pids: updated_pids}}
    end
  end

  @impl true
  def handle_call({:legal_moves, player_id}, _from, state) do
    game = state.game

    # Find player's seat
    case find_player_seat(game, player_id) do
      nil ->
        {:reply, {:error, "Player not in game"}, state}

      seat ->
        # Get player's hand
        hand = game.hands[seat] || []

        # Filter legal moves
        legal_moves = Enum.filter(hand, &Game.is_legal_move?(game, seat, &1))

        {:reply, {:ok, legal_moves}, state}
    end
  end

  @impl true
  def handle_cast({:player_disconnect, player_id}, state) do
    # If player exists and is not already disconnected
    if Map.has_key?(state.player_pids, player_id) and not Map.has_key?(state.disconnected_players, player_id) do
      # Start a timer for disconnection
      timer = Process.send_after(self(), {:player_timeout, player_id}, @reconnect_timeout)

      # Update state to mark player as disconnected with a timestamp
      disconnected = Map.put(state.disconnected_players, player_id, DateTime.utc_now())
      timers = Map.put(state.timers, player_id, timer)

      broadcast_event(state.game.id, :player_disconnected, %{player_id: player_id})

      {:noreply, %{state | disconnected_players: disconnected, timers: timers}}
    else
      {:noreply, state}
    end
  end

  @impl true
  def handle_info({:player_timeout, player_id}, state) do
    # Player didn't reconnect in time, handle the permanent disconnect
    # For this MVP, we just leave their seat empty but keep their data
    # In a more complex implementation, we'd replace them with an AI player

    # Remove the player's PID but leave them in the game's players list
    updated_pids = Map.delete(state.player_pids, player_id)
    updated_disconnected = Map.delete(state.disconnected_players, player_id)
    updated_timers = Map.delete(state.timers, player_id)

    broadcast_event(state.game.id, :player_timeout, %{player_id: player_id})

    {:noreply, %{state |
      player_pids: updated_pids,
      disconnected_players: updated_disconnected,
      timers: updated_timers
    }}
  end

  # Helper functions

  defp find_player_seat(game, player_id) do
    game.players
    |> Enum.find(fn player -> player.id == player_id end)
    |> case do
      nil -> nil
      player -> player.seat
    end
  end

  defp broadcast_state(game) do
    PubSub.broadcast(Lora.PubSub, "game:#{game.id}", {:game_state, game})
  end

  defp broadcast_event(game_id, event, payload) do
    PubSub.broadcast(Lora.PubSub, "game:#{game_id}", {event, payload})
  end
end
