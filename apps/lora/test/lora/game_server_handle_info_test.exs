defmodule Lora.GameServerHandleInfoTest do
  use ExUnit.Case, async: false

  alias Lora.GameServer

  # Use a unique game_id for each test to avoid conflicts
  setup do
    game_id = "game-#{:erlang.unique_integer([:positive])}"
    start_supervised!({GameServer, game_id})
    %{game_id: game_id}
  end

  describe "player timeout" do
    test "handles player timeout when disconnected", %{game_id: game_id} do
      # Add a player
      {:ok, _game_state} = GameServer.add_player(game_id, "player-1", "Alice")

      # Get the GenServer process
      [{pid, _}] = Registry.lookup(Lora.GameRegistry, game_id)

      # Disconnect the player (this would normally trigger a timer)
      :ok = GameServer.player_disconnect(game_id, "player-1")

      # Manually send a player_timeout message to simulate the timer completing
      send(pid, {:player_timeout, "player-1"})

      # Give the GenServer time to process the message
      :timer.sleep(10)

      # Player should still be in the game (according to the implementation)
      {:ok, updated_state} = GameServer.get_state(game_id)
      player = Enum.find(updated_state.players, fn p -> p.id == "player-1" end)
      assert player != nil
    end
  end

  describe "internal state management" do
    # Testing internal functions via the handle_info callback
    test "broadcasts game state correctly", %{game_id: game_id} do
      # Subscribe to the game's PubSub channel
      Phoenix.PubSub.subscribe(Lora.PubSub, "game:#{game_id}")

      # Add a player to trigger state broadcast
      {:ok, _} = GameServer.add_player(game_id, "player-1", "Alice")

      # We should receive the game state update
      assert_receive {:game_state, updated_game}, 500
      assert updated_game.id == game_id
      assert length(updated_game.players) == 1

      player = List.first(updated_game.players)
      assert player.name == "Alice"
    end

    test "broadcasts events correctly", %{game_id: game_id} do
      # Subscribe to the game's PubSub channel
      Phoenix.PubSub.subscribe(Lora.PubSub, "game:#{game_id}")

      # Add a player to trigger event broadcast
      {:ok, game_state} = GameServer.add_player(game_id, "player-1", "Alice")

      # Get the actual seat number from the game state
      player = List.first(game_state.players)
      seat = player.seat

      # We should receive the player_joined event
      assert_receive {:player_joined, %{player: "Alice", seat: ^seat}}, 500
    end
  end
end
