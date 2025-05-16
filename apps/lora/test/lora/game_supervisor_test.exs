defmodule Lora.GameSupervisorTest do
  use ExUnit.Case, async: false

  alias Lora.GameSupervisor
  alias Lora.GameServer

  describe "game creation" do
    test "create_game/2 creates a game with random ID and adds the creator as first player" do
      player_id = "player-1"
      player_name = "Alice"

      {:ok, game_id} = GameSupervisor.create_game(player_id, player_name)

      # Check that the game exists
      assert GameSupervisor.game_exists?(game_id)

      # Check that the player is in the game
      {:ok, game_state} = GameServer.get_state(game_id)
      assert length(game_state.players) == 1
      player = List.first(game_state.players)
      assert player.id == player_id
      assert player.name == player_name

      # Cleanup
      GameSupervisor.stop_game(game_id)
    end

    test "create_game_with_id/3 creates a game with specific ID" do
      player_id = "player-1"
      player_name = "Bob"
      game_id = "TEST01"

      {:ok, ^game_id} = GameSupervisor.create_game_with_id(game_id, player_id, player_name)

      # Check that the game exists with the specified ID
      assert GameSupervisor.game_exists?(game_id)

      # Check that the player is in the game
      {:ok, game_state} = GameServer.get_state(game_id)
      assert length(game_state.players) == 1
      player = List.first(game_state.players)
      assert player.id == player_id
      assert player.name == player_name

      # Cleanup
      GameSupervisor.stop_game(game_id)
    end

    test "start_game/1 starts a game server for a given ID" do
      game_id = "TEST02"

      {:ok, _pid} = GameSupervisor.start_game(game_id)

      # Check that the game exists
      assert GameSupervisor.game_exists?(game_id)

      # Cleanup
      GameSupervisor.stop_game(game_id)
    end

    test "stop_game/1 stops a game server" do
      game_id = "TEST03"

      {:ok, pid} = GameSupervisor.start_game(game_id)
      assert GameSupervisor.game_exists?(game_id)

      # Monitor the process to be notified when it terminates
      ref = Process.monitor(pid)

      :ok = GameSupervisor.stop_game(game_id)

      # Wait for the DOWN message from the monitored process
      assert_receive {:DOWN, ^ref, :process, ^pid, _}, 500

      # Verify the process is no longer alive
      refute Process.alive?(pid)

      # Registry cleanup may happen asynchronously, so we'll verify the process is terminated
      # rather than immediately checking game_exists?
    end

    test "stop_game/1 returns error for non-existent game" do
      assert {:error, :not_found} = GameSupervisor.stop_game("NONEXISTENT")
    end
  end

  describe "utility functions" do
    test "generate_game_id/0 creates a 6-character ID" do
      id = GameSupervisor.generate_game_id()
      assert String.length(id) == 6
      assert id =~ ~r/^[ABCDEFGHJKLMNPQRSTUVWXYZ23456789]{6}$/
    end

    test "game_exists?/1 checks if a game exists" do
      game_id = "TEST04"

      # Game shouldn't exist initially
      refute GameSupervisor.game_exists?(game_id)

      # Create the game
      {:ok, pid} = GameSupervisor.start_game(game_id)
      assert GameSupervisor.game_exists?(game_id)

      # Cleanup
      ref = Process.monitor(pid)
      GameSupervisor.stop_game(game_id)
      assert_receive {:DOWN, ^ref, :process, ^pid, _}, 500

      # Verify the process is no longer alive
      refute Process.alive?(pid)
    end
  end
end
