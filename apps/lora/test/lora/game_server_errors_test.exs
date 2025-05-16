defmodule Lora.GameServerErrorsTest do
  use ExUnit.Case, async: false

  alias Lora.GameServer

  setup do
    game_id = "game-#{:erlang.unique_integer([:positive])}"
    start_supervised!({GameServer, game_id})
    %{game_id: game_id}
  end

  describe "error handling for player actions" do
    test "play_card/3 returns error for invalid player ID", %{game_id: game_id} do
      # Try to play a card as a non-existent player
      result = GameServer.play_card(game_id, "non-existent-player", {:hearts, :ace})
      assert {:error, "Player not in game"} = result
    end

    test "legal_moves/2 returns error for invalid player ID", %{game_id: game_id} do
      # Try to get legal moves for a non-existent player
      result = GameServer.legal_moves(game_id, "non-existent-player")
      assert {:error, "Player not in game"} = result
    end

    test "pass_lora/2 returns error for invalid player ID", %{game_id: game_id} do
      # Try to pass in Lora as a non-existent player
      result = GameServer.pass_lora(game_id, "non-existent-player")
      assert {:error, "Player not in game"} = result
    end
  end

  describe "player management edge cases" do
    setup %{game_id: game_id} do
      # Add a test player
      {:ok, game_state} = GameServer.add_player(game_id, "player1", "Alice")
      player = List.first(game_state.players)
      %{player: player}
    end

    test "player_reconnect/3 for a player that's not disconnected", %{
      game_id: game_id,
      player: player
    } do
      # Reconnect without disconnecting first
      result = GameServer.player_reconnect(game_id, player.id, self())
      # Should still succeed, just updates the PID
      assert {:ok, _} = result
    end

    test "player_disconnect/2 for an already disconnected player", %{
      game_id: game_id,
      player: player
    } do
      # Disconnect once
      :ok = GameServer.player_disconnect(game_id, player.id)

      # Disconnect again
      :ok = GameServer.player_disconnect(game_id, player.id)

      # Should handle this gracefully (not crash)
      # The implementation just keeps the existing disconnection state
      {:ok, game_state} = GameServer.get_state(game_id)
      assert Enum.any?(game_state.players, fn p -> p.id == player.id end)
    end

    test "player_disconnect/2 for non-existent player", %{game_id: game_id} do
      # Should not crash when disconnecting a non-existent player
      :ok = GameServer.player_disconnect(game_id, "non-existent-player")
    end
  end

  describe "game server process handling" do
    test "via_tuple resolves to the correct process", %{game_id: game_id} do
      # Get the actual PID from the Registry
      [{actual_pid, _}] = Registry.lookup(Lora.GameRegistry, game_id)

      # Call get_state to verify it's working
      {:ok, game_state} = GameServer.get_state(game_id)
      assert game_state.id == game_id

      # Verify the PID is alive
      assert Process.alive?(actual_pid)
    end
  end
end
