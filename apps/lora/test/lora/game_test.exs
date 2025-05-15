defmodule Lora.GameTest do
  use ExUnit.Case

  alias Lora.Game

  describe "game initialization" do
    test "new_game/1 creates a game with correct initial state" do
      game = Game.new_game("test-game")

      assert game.id == "test-game"
      assert game.players == []
      assert game.dealer_seat == 1
      assert game.contract_index == 0
      assert game.phase == :lobby
      assert game.current_player == nil
      assert game.dealt_count == 0
      assert game.scores == %{1 => 0, 2 => 0, 3 => 0, 4 => 0}
    end
  end

  describe "player management" do
    test "add_player/3 adds a player to the game" do
      game = Game.new_game("test-game")

      {:ok, game} = Game.add_player(game, "player1", "Alice")

      assert length(game.players) == 1
      player = List.first(game.players)
      assert player.id == "player1"
      assert player.name == "Alice"
      assert player.seat == 1
    end

    test "add_player/3 fails if the player is already in the game" do
      game = Game.new_game("test-game")
      {:ok, game} = Game.add_player(game, "player1", "Alice")

      result = Game.add_player(game, "player1", "Alice Again")

      assert result == {:error, "Player already in game"}
    end

    test "add_player/3 fails if the game is full" do
      game = Game.new_game("test-game")

      {:ok, game} = Game.add_player(game, "player1", "Alice")
      {:ok, game} = Game.add_player(game, "player2", "Bob")
      {:ok, game} = Game.add_player(game, "player3", "Charlie")
      {:ok, game} = Game.add_player(game, "player4", "Dave")

      result = Game.add_player(game, "player5", "Eve")

      # The game actually fails because it has already started when the 4th player joined
      assert result == {:error, "Cannot join a game that has already started"}
    end

    test "add_player/3 starts the game when the fourth player joins" do
      game = Game.new_game("test-game")

      {:ok, game} = Game.add_player(game, "player1", "Alice")
      {:ok, game} = Game.add_player(game, "player2", "Bob")
      {:ok, game} = Game.add_player(game, "player3", "Charlie")

      assert game.phase == :lobby
      assert game.current_player == nil

      {:ok, game} = Game.add_player(game, "player4", "Dave")

      assert game.phase == :playing
      assert game.current_player != nil
      assert game.dealt_count == 1

      # Each player should have 8 cards
      Enum.each(1..4, fn seat ->
        assert length(game.hands[seat]) == 8
      end)
    end
  end

  describe "game actions" do
    setup do
      game = Game.new_game("test-game")

      {:ok, game} = Game.add_player(game, "player1", "Alice")
      {:ok, game} = Game.add_player(game, "player2", "Bob")
      {:ok, game} = Game.add_player(game, "player3", "Charlie")
      {:ok, game} = Game.add_player(game, "player4", "Dave")

      %{game: game}
    end

    test "play_card/3 plays a card from the current player's hand", %{game: game} do
      # Find the current player and a card in their hand
      current_seat = game.current_player
      card = List.first(game.hands[current_seat])

      # Try to play the card
      {:ok, new_game} = Game.play_card(game, current_seat, card)

      # Card should no longer be in the player's hand
      refute card_in_hand?(new_game.hands[current_seat], card)

      # Card should be in the trick
      assert Enum.any?(new_game.trick, fn {seat, played_card} ->
               seat == current_seat && played_card == card
             end)
    end

    test "play_card/3 fails when it's not the player's turn", %{game: game} do
      # Find a seat that's not the current player
      other_seat = Enum.find(1..4, fn seat -> seat != game.current_player end)
      card = List.first(game.hands[other_seat])

      result = Game.play_card(game, other_seat, card)

      assert result == {:error, "Not your turn"}
    end

    test "play_card/3 fails with illegal moves", %{game: game} do
      current_seat = game.current_player

      # We need to create a very specific test scenario
      # First, empty the player's hand and add specific cards
      hands =
        Map.put(game.hands, current_seat, [
          {:spades, :ace},
          {:spades, :king},
          {:diamonds, :ace}
        ])

      # Add a trick with a card played to establish a lead suit of spades
      trick = [{rem(current_seat + 1, 4) + 1, {:spades, :jack}}]

      # Update the game state
      game = %{game | hands: hands, trick: trick}

      # Try to play diamonds when we have spades (should be illegal)
      result = Game.play_card(game, current_seat, {:diamonds, :ace})

      # We expect an error about illegal move
      assert {:error, "Illegal move"} = result
    end

    test "next_dealer_and_contract/1 rotates contract and dealer properly", %{game: game} do
      # Initial state: dealer_seat = 1, contract_index = 0
      assert game.dealer_seat == 1
      assert game.contract_index == 0

      # Test next contract for same dealer
      {dealer, contract} = Game.next_dealer_and_contract(%{game | contract_index: 0})
      assert dealer == 1
      assert contract == 1

      # Test next dealer when contract rotates back to 0
      {dealer, contract} = Game.next_dealer_and_contract(%{game | contract_index: 6})
      assert dealer == 2
      assert contract == 0
    end
  end

  # Helper function to check if a card is in a hand
  defp card_in_hand?(hand, card) do
    Enum.member?(hand, card)
  end
end
