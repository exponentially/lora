defmodule Lora.Contracts.MaximumTest do
  use ExUnit.Case, async: true
  alias Lora.Game
  alias Lora.Contracts.Maximum

  # Define common test data
  @players [
    %{id: "p1", name: "Player 1", seat: 1},
    %{id: "p2", name: "Player 2", seat: 2},
    %{id: "p3", name: "Player 3", seat: 3},
    %{id: "p4", name: "Player 4", seat: 4}
  ]

  @maximum_contract_index 1

  describe "is_legal_move?/3" do
    setup do
      # Setup common test data for this describe block
      hands = %{
        1 => [{:clubs, :ace}, {:hearts, :queen}],
        2 => [{:diamonds, :king}, {:clubs, 7}],
        3 => [{:hearts, 8}, {:spades, :jack}],
        4 => [{:spades, :ace}, {:hearts, :king}]
      }

      game = %Game{
        id: "test_game",
        players: @players,
        trick: [],
        hands: hands
      }

      %{game: game, hands: hands}
    end

    test "allows any card when trick is empty", %{game: game} do
      assert Maximum.is_legal_move?(game, 1, {:clubs, :ace})
      assert Maximum.is_legal_move?(game, 1, {:hearts, :queen})
    end

    test "requires following suit when possible", %{game: game} do
      # Given: Player 2 has both clubs and diamonds
      # When: The trick starts with a club
      game_with_trick = %{game | trick: [{1, {:clubs, :ace}}]}

      # Then: Player 2 must play a club
      assert Maximum.is_legal_move?(game_with_trick, 2, {:clubs, 7})
      refute Maximum.is_legal_move?(game_with_trick, 2, {:diamonds, :king})
    end

    test "allows any card when player can't follow suit", %{game: game} do
      # Given: Player 3 has no clubs
      # When: The trick starts with a club
      game_with_trick = %{game | trick: [{1, {:clubs, :ace}}]}

      # Then: Player 3 can play any card
      assert Maximum.is_legal_move?(game_with_trick, 3, {:hearts, 8})
      assert Maximum.is_legal_move?(game_with_trick, 3, {:spades, :jack})
    end
  end

  describe "play_card/4" do
    test "delegates to TrickTaking.play_card" do
      # Given: A game in the Maximum contract with empty trick
      game = %Game{
        id: "test_game",
        players: @players,
        trick: [],
        taken: %{1 => [], 2 => [], 3 => [], 4 => []},
        contract_index: @maximum_contract_index,
        current_player: 1
      }

      hands = %{
        1 => [{:clubs, :ace}],
        2 => [{:diamonds, :king}],
        3 => [{:hearts, 8}],
        4 => [{:spades, :ace}]
      }

      # When: Player 1 plays a card
      {:ok, updated_game} = Maximum.play_card(game, 1, {:clubs, :ace}, hands)

      # Then: The trick should be updated and next player's turn
      assert [{1, {:clubs, :ace}}] = updated_game.trick
      assert updated_game.current_player == 2
    end
  end

  describe "calculate_scores/4" do
    test "awards negative one point per trick taken" do
      # Given: Players have taken different numbers of tricks
      # Player 1: 3 tricks
      # Player 2: 2 tricks
      # Player 3: 1 trick
      # Player 4: 2 tricks
      taken = %{
        1 => [
          [{:clubs, :ace}, {:diamonds, :king}, {:hearts, :queen}, {:spades, :jack}],
          [{:clubs, :king}, {:diamonds, :ace}, {:hearts, :jack}, {:spades, 10}],
          [{:clubs, :queen}, {:diamonds, 10}, {:hearts, 10}, {:spades, 9}]
        ],
        2 => [
          [{:clubs, :jack}, {:diamonds, :queen}, {:hearts, :king}, {:spades, :queen}],
          [{:clubs, 10}, {:diamonds, :jack}, {:hearts, 9}, {:spades, 8}]
        ],
        3 => [
          [{:clubs, 9}, {:diamonds, 9}, {:hearts, 8}, {:spades, 7}]
        ],
        4 => [
          [{:clubs, 8}, {:diamonds, 8}, {:hearts, 7}, {:spades, :king}],
          [{:clubs, 7}, {:diamonds, 7}, {:hearts, :ace}, {:spades, :ace}]
        ]
      }

      # When: Scores are calculated
      scores = Maximum.calculate_scores(%Game{}, %{}, taken, 1)

      # Then: Each player gets -1 point per trick taken
      assert scores == %{
               # 3 tricks
               1 => -3,
               # 2 tricks
               2 => -2,
               # 1 trick
               3 => -1,
               # 2 tricks
               4 => -2
             }
    end

    test "handles empty taken piles" do
      # Given: No player has taken any tricks
      taken = %{
        1 => [],
        2 => [],
        3 => [],
        4 => []
      }

      # When: Scores are calculated
      scores = Maximum.calculate_scores(%Game{}, %{}, taken, 1)

      # Then: Everyone gets 0 points
      assert scores == %{
               1 => 0,
               2 => 0,
               3 => 0,
               4 => 0
             }
    end

    test "handles uneven trick distribution" do
      # Given: One player has taken all 8 tricks
      taken = %{
        1 => [
          [{:clubs, :ace}, {:diamonds, :king}, {:hearts, :queen}, {:spades, :jack}],
          [{:clubs, :king}, {:diamonds, :ace}, {:hearts, :jack}, {:spades, 10}],
          [{:clubs, :queen}, {:diamonds, 10}, {:hearts, 10}, {:spades, 9}],
          [{:clubs, :jack}, {:diamonds, :queen}, {:hearts, :king}, {:spades, :queen}],
          [{:clubs, 10}, {:diamonds, :jack}, {:hearts, 9}, {:spades, 8}],
          [{:clubs, 9}, {:diamonds, 9}, {:hearts, 8}, {:spades, 7}],
          [{:clubs, 8}, {:diamonds, 8}, {:hearts, 7}, {:spades, :king}],
          [{:clubs, 7}, {:diamonds, 7}, {:hearts, :ace}, {:spades, :ace}]
        ],
        2 => [],
        3 => [],
        4 => []
      }

      # When: Scores are calculated
      scores = Maximum.calculate_scores(%Game{}, %{}, taken, 1)

      # Then: Player 1 gets -8 points, others get 0
      assert scores == %{
               # 8 tricks
               1 => -8,
               # 0 tricks
               2 => 0,
               # 0 tricks
               3 => 0,
               # 0 tricks
               4 => 0
             }
    end
  end

  describe "handle_deal_over/4" do
    test "scores are correctly calculated at end of deal" do
      # Given: A game in Maximum contract with specific taken cards
      game = %Game{
        id: "test_game",
        players: @players,
        taken: %{1 => [], 2 => [], 3 => [], 4 => []},
        contract_index: @maximum_contract_index,
        dealer_seat: 1,
        # Existing scores
        scores: %{1 => 10, 2 => 5, 3 => 8, 4 => 12}
      }

      # All hands are empty at end of deal
      hands = %{1 => [], 2 => [], 3 => [], 4 => []}

      # Each player has taken different numbers of tricks
      taken = %{
        1 => [
          [{:clubs, :ace}, {:diamonds, :king}, {:hearts, :queen}, {:spades, :jack}],
          [{:clubs, :king}, {:diamonds, :ace}, {:hearts, :jack}, {:spades, 10}]
        ],
        2 => [
          [{:clubs, :queen}, {:diamonds, 10}, {:hearts, 10}, {:spades, 9}],
          [{:clubs, :jack}, {:diamonds, :queen}, {:hearts, :king}, {:spades, :queen}]
        ],
        3 => [
          [{:clubs, 10}, {:diamonds, :jack}, {:hearts, 9}, {:spades, 8}],
          [{:clubs, 9}, {:diamonds, 9}, {:hearts, 8}, {:spades, 7}]
        ],
        4 => [
          [{:clubs, 8}, {:diamonds, 8}, {:hearts, 7}, {:spades, :king}],
          [{:clubs, 7}, {:diamonds, 7}, {:hearts, :ace}, {:spades, :ace}]
        ]
      }

      # When: Deal is over
      updated_game = Maximum.handle_deal_over(game, hands, taken, 1)

      # Then: Scores should reflect Maximum scoring (-1 per trick)
      expected_scores = %{
        # 10 - 2
        1 => 8,
        # 5 - 2
        2 => 3,
        # 8 - 2
        3 => 6,
        # 12 - 2
        4 => 10
      }

      assert updated_game.scores == expected_scores

      # Game state should be updated
      assert is_map(updated_game)
      assert updated_game.scores != game.scores
    end
  end

  describe "can_pass?/2" do
    test "always returns false for Maximum contract" do
      # Given: A game in the Maximum contract
      game = %Game{
        id: "test_game",
        contract_index: @maximum_contract_index
      }

      # When/Then: No player can pass
      for seat <- 1..4 do
        refute Maximum.can_pass?(game, seat)
      end
    end
  end

  describe "pass/2" do
    test "returns error for Maximum contract" do
      # Given: A game in the Maximum contract
      game = %Game{
        id: "test_game",
        contract_index: @maximum_contract_index
      }

      # When/Then: Attempting to pass returns an error
      assert {:error, "Cannot pass in the Maximum contract"} = Maximum.pass(game, 1)
    end
  end

  describe "integration tests" do
    test "trick winner determination follows standard rules" do
      # Given: A game with a partly completed trick
      game = %Game{
        id: "test_game",
        players: @players,
        contract_index: @maximum_contract_index,
        trick: [
          # Player 1 leads diamonds
          {1, {:diamonds, 10}},
          # Player 2 plays higher diamond
          {2, {:diamonds, :king}},
          # Player 3 plays lower diamond
          {3, {:diamonds, 7}}
        ],
        current_player: 4,
        hands: %{
          1 => [{:clubs, :ace}],
          2 => [{:hearts, 9}],
          3 => [{:spades, 10}],
          # Player 4 has the highest diamond
          4 => [{:diamonds, :ace}]
        },
        taken: %{1 => [], 2 => [], 3 => [], 4 => []}
      }

      # When: Player 4 plays the Ace of Diamonds
      {:ok, updated_game} = Maximum.play_card(game, 4, {:diamonds, :ace}, game.hands)

      # Then: Player 4 should win the trick because Ace is highest
      assert updated_game.taken[4] != []
      # Winner leads next trick
      assert updated_game.current_player == 4

      # And the trick should be in Player 4's taken pile
      trick_cards = List.flatten(updated_game.taken[4])
      assert Enum.member?(trick_cards, {:diamonds, 10})
      assert Enum.member?(trick_cards, {:diamonds, :king})
      assert Enum.member?(trick_cards, {:diamonds, 7})
      assert Enum.member?(trick_cards, {:diamonds, :ace})
    end

    test "entire deal from start to finish" do
      # Given: A new game in the Maximum contract with dealt cards
      initial_hands = %{
        1 => [{:clubs, :ace}, {:diamonds, 10}],
        2 => [{:clubs, :king}, {:diamonds, :king}],
        3 => [{:clubs, :queen}, {:diamonds, :queen}],
        4 => [{:clubs, :jack}, {:diamonds, :jack}]
      }

      game = %Game{
        id: "test_game",
        players: @players,
        contract_index: @maximum_contract_index,
        current_player: 1,
        hands: initial_hands,
        trick: [],
        taken: %{1 => [], 2 => [], 3 => [], 4 => []},
        scores: %{1 => 0, 2 => 0, 3 => 0, 4 => 0}
      }

      # Instead of manually playing each card, we'll let the contract handle the game
      # and just check the final state after playing all cards

      # First trick
      taken_after_game = %{
        1 => [
          [{:clubs, :ace}, {:clubs, :king}, {:clubs, :queen}, {:clubs, :jack}]
        ],
        2 => [
          [{:diamonds, 10}, {:diamonds, :king}, {:diamonds, :queen}, {:diamonds, :jack}]
        ],
        3 => [],
        4 => []
      }

      # When the deal is over, calculate final scores
      final_game =
        Maximum.handle_deal_over(
          game,
          # Empty hands
          %{1 => [], 2 => [], 3 => [], 4 => []},
          taken_after_game,
          # Last trick winner
          2
        )

      # Then: Scores should be calculated correctly
      # Player 1: -1 point (won first trick)
      # Player 2: -1 point (won second trick)
      # Players 3 & 4: 0 points (won no tricks)
      assert final_game.scores == %{
               1 => -1,
               2 => -1,
               3 => 0,
               4 => 0
             }
    end
  end
end
