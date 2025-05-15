defmodule Lora.GameServerCompletionTest do
  use ExUnit.Case, async: false

  alias Lora.GameServer
  alias Phoenix.PubSub

  # Use a unique game_id for each test to avoid conflicts
  setup do
    game_id = "game-#{:erlang.unique_integer([:positive])}"
    start_supervised!({GameServer, game_id})
    %{game_id: game_id}
  end

  describe "game state transitions" do
    test "game reaches playing state when 4 players join", %{game_id: game_id} do
      # Subscribe to the game's PubSub channel
      PubSub.subscribe(Lora.PubSub, "game:#{game_id}")

      # Add 4 players to start the game
      {:ok, _} = GameServer.add_player(game_id, "player1", "Alice")
      {:ok, _} = GameServer.add_player(game_id, "player2", "Bob")
      {:ok, _} = GameServer.add_player(game_id, "player3", "Charlie")
      {:ok, game_state} = GameServer.add_player(game_id, "player4", "Dave")

      # Game should transition to playing state
      assert game_state.phase == :playing

      # We should receive the game_started event
      assert_receive {:game_started, _payload}, 500
    end
  end

  describe "game state management" do
    test "updates game state correctly", %{game_id: game_id} do
      # Get the pid of the game server
      [{_pid, _}] = Registry.lookup(Lora.GameRegistry, game_id)

      # Initialize with no players
      {:ok, initial_state} = GameServer.get_state(game_id)
      assert initial_state.players == []

      # Add a player
      {:ok, updated_state} = GameServer.add_player(game_id, "player1", "Alice")
      assert length(updated_state.players) == 1

      # Check player details
      player = List.first(updated_state.players)
      assert player.id == "player1"
      assert player.name == "Alice"
    end

    test "maintains game state across calls", %{game_id: game_id} do
      # Verify state persistence
      {:ok, _} = GameServer.add_player(game_id, "player1", "Alice")
      {:ok, state_after_add} = GameServer.get_state(game_id)
      assert length(state_after_add.players) == 1

      # After a disconnect, player should still be in the game
      :ok = GameServer.player_disconnect(game_id, "player1")

      {:ok, state_after_disconnect} = GameServer.get_state(game_id)
      assert length(state_after_disconnect.players) == 1
      assert List.first(state_after_disconnect.players).id == "player1"
    end
  end
end
