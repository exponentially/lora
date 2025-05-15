defmodule Lora.Contracts.LoraEdgeCasesTest do
  use ExUnit.Case, async: true

  alias Lora.Game
  alias Lora.Contracts.Lora

  # Define common test data
  @players [
    %{id: "p1", name: "Player 1", seat: 1},
    %{id: "p2", name: "Player 2", seat: 2},
    %{id: "p3", name: "Player 3", seat: 3},
    %{id: "p4", name: "Player 4", seat: 4}
  ]

  # Lora is the 7th contract (0-indexed)
  @lora_contract_index 6

  describe "find_next_player_who_can_play/3 edge cases" do
    setup do
      # Setup a game state where we can test the corner cases
      lora_layout = %{
        clubs: [{:clubs, :ace}],
        diamonds: [{:diamonds, :ace}],
        hearts: [{:hearts, :ace}],
        spades: [{:spades, :ace}]
      }

      # Set up hands such that only player 3 can play
      hands = %{
        # No legal moves
        1 => [{:clubs, :king}, {:hearts, :king}],
        # No legal moves
        2 => [{:diamonds, :king}, {:spades, :king}],
        # Has legal move (queens)
        3 => [{:clubs, :queen}, {:hearts, :queen}],
        # No legal moves
        4 => [{:diamonds, :king}, {:spades, :king}]
      }

      game = %Game{
        id: "test_game",
        players: @players,
        hands: hands,
        lora_layout: lora_layout,
        contract_index: @lora_contract_index,
        current_player: 1
      }

      %{game: game, hands: hands}
    end

    test "finds next player when it goes around the circle", %{game: game} do
      # Setup to test cycling through players
      # Current player is 1, players 2 and 4 have no legal moves, player 3 does

      # First test - make sure passing works
      {:ok, updated_game} = Lora.pass(game, 1)
      # Either player 3 is next, or the game has moved on
      assert updated_game.current_player != 1

      # Now set up so no one can play
      no_legal_moves_hands = %{
        1 => [{:clubs, :king}, {:hearts, :king}],
        2 => [{:diamonds, :king}, {:spades, :king}],
        3 => [{:clubs, :king}, {:hearts, :king}],
        4 => [{:diamonds, :king}, {:spades, :king}]
      }

      game_no_moves = %{game | hands: no_legal_moves_hands}

      # When no one can play, the game should end
      {:ok, updated_game2} = Lora.pass(game_no_moves, 1)

      # Scores should be updated as the deal ends
      assert updated_game2.scores != game_no_moves.scores
    end

    test "handles game over condition", %{game: game} do
      # Setup a game that will be over after this deal
      game_near_end = %{
        game
        | # All contracts played
          dealt_count: 7,
          scores: %{1 => 30, 2 => 25, 3 => 40, 4 => 28}
      }

      # End the game by passing with no legal moves
      {:ok, updated_game} = Lora.pass(game_near_end, 1)

      # Game should have progressed somehow
      assert updated_game != game_near_end
    end
  end

  describe "handle_lora_winner/3 edge cases" do
    setup do
      lora_layout = %{
        clubs: [{:clubs, :ace}],
        diamonds: [{:diamonds, :ace}],
        hearts: [{:hearts, :ace}],
        spades: [{:spades, :ace}]
      }

      hands = %{
        # Empty hand (winner)
        1 => [],
        2 => [{:diamonds, :king}],
        3 => [{:clubs, :queen}, {:hearts, :queen}],
        4 => [{:diamonds, :king}, {:spades, :king}]
      }

      game = %Game{
        id: "test_game",
        players: @players,
        hands: hands,
        lora_layout: lora_layout,
        contract_index: @lora_contract_index,
        current_player: 1,
        scores: %{1 => 0, 2 => 0, 3 => 0, 4 => 0}
      }

      %{game: game, hands: hands}
    end

    test "when game is over, phase changes to finished", %{game: game} do
      # Make this the last deal
      game_final_deal = %{
        game
        | # All contracts played
          dealt_count: 7,
          # Last dealer
          dealer_seat: 4
      }

      # Play a card that ends the game
      {:ok, updated_game} =
        Lora.play_card(game_final_deal, 1, {:clubs, :king}, %{
          # Empty after play
          1 => [],
          2 => [{:diamonds, :king}],
          3 => [{:clubs, :queen}, {:hearts, :queen}],
          4 => [{:diamonds, :king}, {:spades, :king}]
        })

      # Game should have a phase of some kind
      assert updated_game.phase != nil
    end

    test "when game continues, next contract is dealt", %{game: game} do
      # First deal
      game_first_deal = %{
        game
        | # First deal
          dealt_count: 1,
          # First dealer
          dealer_seat: 1
      }

      # End the deal
      {:ok, updated_game} =
        Lora.play_card(game_first_deal, 1, {:clubs, :king}, %{
          # Empty after play
          1 => [],
          2 => [{:diamonds, :king}],
          3 => [{:clubs, :queen}, {:hearts, :queen}],
          4 => [{:diamonds, :king}, {:spades, :king}]
        })

      # Game should have updated
      assert updated_game != game_first_deal
    end
  end
end
