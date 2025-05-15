defmodule Lora.GameServerPubSubTest do
  use ExUnit.Case, async: false

  alias Lora.GameServer

  # Use a unique game_id for each test to avoid conflicts
  setup do
    game_id = "game-#{:erlang.unique_integer([:positive])}"
    start_supervised!({GameServer, game_id})
    %{game_id: game_id}
  end

  describe "pubsub events" do
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

    test "broadcasts player reconnect events", %{game_id: game_id} do
      # Subscribe to the game's PubSub channel
      Phoenix.PubSub.subscribe(Lora.PubSub, "game:#{game_id}")

      # Add a player
      {:ok, _} = GameServer.add_player(game_id, "player-1", "Alice")

      # Disconnect then reconnect to trigger events
      :ok = GameServer.player_disconnect(game_id, "player-1")
      {:ok, _} = GameServer.player_reconnect(game_id, "player-1", self())

      # We should receive the disconnection and reconnection events
      assert_receive {:player_disconnected, %{player_id: "player-1"}}, 500
      assert_receive {:player_reconnected, %{player_id: "player-1"}}, 500
    end

    test "broadcasts game started event when 4 players join", %{game_id: game_id} do
      # Subscribe to the game's PubSub channel
      Phoenix.PubSub.subscribe(Lora.PubSub, "game:#{game_id}")

      # Add 4 players
      {:ok, _} = GameServer.add_player(game_id, "player-1", "Alice")
      {:ok, _} = GameServer.add_player(game_id, "player-2", "Bob")
      {:ok, _} = GameServer.add_player(game_id, "player-3", "Charlie")
      {:ok, _} = GameServer.add_player(game_id, "player-4", "Dave")

      # We should receive the game_started event
      assert_receive {:game_started, %{}}, 500
    end

    test "broadcasts card played event", %{game_id: game_id} do
      # Subscribe to the game's PubSub channel
      Phoenix.PubSub.subscribe(Lora.PubSub, "game:#{game_id}")

      # Add 4 players to start the game
      {:ok, _} = GameServer.add_player(game_id, "player-1", "Alice")
      {:ok, _} = GameServer.add_player(game_id, "player-2", "Bob")
      {:ok, _} = GameServer.add_player(game_id, "player-3", "Charlie")
      {:ok, game_state} = GameServer.add_player(game_id, "player-4", "Dave")

      # Find the current player and a card in their hand
      current_seat = game_state.current_player
      current_player = Enum.find(game_state.players, fn p -> p.seat == current_seat end)
      card = hd(game_state.hands[current_seat])

      # Play the card
      {:ok, _} = GameServer.play_card(game_id, current_player.id, card)

      # We should receive the card_played event
      assert_receive {:card_played, %{card: ^card}}, 500
    end
  end
end
