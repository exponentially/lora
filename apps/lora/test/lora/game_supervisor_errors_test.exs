defmodule Lora.GameSupervisorErrorsTest do
  use ExUnit.Case, async: false

  alias Lora.GameSupervisor
  alias Lora.GameServer

  describe "error handling" do
    test "create_game_with_id/3 fails when game ID already exists" do
      player_id = "player-1"
      player_name = "Alice"
      game_id = "DUPLICATE"

      # Create a game with the ID first
      {:ok, ^game_id} = GameSupervisor.create_game_with_id(game_id, player_id, player_name)

      # Try to create another game with the same ID
      player_id2 = "player-2"
      player_name2 = "Bob"

      result = GameSupervisor.create_game_with_id(game_id, player_id2, player_name2)
      assert {:error, {:already_started, _}} = result

      # Cleanup
      GameSupervisor.stop_game(game_id)
    end

    test "create_game/2 rolls back when player cannot be added" do
      # Create a unique game ID for this test
      game_id_atom = String.to_atom("test-#{:erlang.unique_integer([:positive])}")

      # Mock the add_player function to simulate a failure
      :meck.new(GameServer, [:passthrough])
      :meck.expect(GameServer, :add_player, fn _game_id, _player_id, _player_name ->
        {:error, "Failed to add player"}
      end)

      # Try to create a game - it should fail since add_player fails
      result = GameSupervisor.create_game("invalid-player", "Invalid Name")
      assert {:error, "Failed to add player"} = result

      # Verify the game server was not left running
      assert Registry.lookup(Lora.GameRegistry, game_id_atom) == []

      # Clean up the mock
      :meck.unload(GameServer)
    end

    test "create_game_with_id handles failures from add_player" do
      # Mock the add_player function to simulate a failure
      :meck.new(GameServer, [:passthrough])
      :meck.expect(GameServer, :add_player, fn _game_id, _player_id, _player_name ->
        {:error, "Failed to add player"}
      end)

      # Try to create a game - it should fail since add_player fails
      game_id = "ERROR01"
      result = GameSupervisor.create_game_with_id(game_id, "invalid-player", "Invalid Name")
      assert {:error, "Failed to add player"} = result

      # Clean up the mock
      :meck.unload(GameServer)
    end
  end
end
