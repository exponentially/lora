defmodule Lora.Contracts.MinimumTest do
  use ExUnit.Case, async: true
  alias Lora.Game
  alias Lora.Contracts.Minimum

  # Define common test data
  @players [
    %{id: "p1", name: "Player 1", seat: 1},
    %{id: "p2", name: "Player 2", seat: 2},
    %{id: "p3", name: "Player 3", seat: 3},
    %{id: "p4", name: "Player 4", seat: 4}
  ]

  @minimum_contract_index 0

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
      assert Minimum.is_legal_move?(game, 1, {:clubs, :ace})
      assert Minimum.is_legal_move?(game, 1, {:hearts, :queen})
    end

    test "requires following suit when possible", %{game: game} do
      # Given: Player 2 has both clubs and diamonds
      # When: The trick starts with a club
      game_with_trick = %{game | trick: [{1, {:clubs, :ace}}]}
      
      # Then: Player 2 must play a club
      assert Minimum.is_legal_move?(game_with_trick, 2, {:clubs, 7})
      refute Minimum.is_legal_move?(game_with_trick, 2, {:diamonds, :king})
    end

    test "allows any card when player can't follow suit", %{game: game} do
      # Given: Player 3 has no clubs
      # When: The trick starts with a club
      game_with_trick = %{game | trick: [{1, {:clubs, :ace}}]}
      
      # Then: Player 3 can play any card
      assert Minimum.is_legal_move?(game_with_trick, 3, {:hearts, 8})
      assert Minimum.is_legal_move?(game_with_trick, 3, {:spades, :jack})
    end
  end

  describe "play_card/4" do
    test "delegates to TrickTaking.play_card" do
      # Given: A game in the Minimum contract with empty trick
      game = %Game{
        id: "test_game",
        players: @players,
        trick: [],
        taken: %{1 => [], 2 => [], 3 => [], 4 => []},
        contract_index: @minimum_contract_index,
        current_player: 1
      }

      hands = %{
        1 => [{:clubs, :ace}],
        2 => [{:diamonds, :king}],
        3 => [{:hearts, 8}],
        4 => [{:spades, :ace}]
      }

      # When: Player 1 plays a card
      {:ok, updated_game} = Minimum.play_card(game, 1, {:clubs, :ace}, hands)
      
      # Then: The trick should be updated and next player's turn
      assert [{1, {:clubs, :ace}}] = updated_game.trick
      assert updated_game.current_player == 2
    end
  end

  describe "calculate_scores/4" do
    test "awards one point per trick taken" do
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
      scores = Minimum.calculate_scores(%Game{}, %{}, taken, 1)
      
      # Then: Each player gets +1 point per trick taken
      assert scores == %{
        1 => 3,  # 3 tricks
        2 => 2,  # 2 tricks
        3 => 1,  # 1 trick
        4 => 2   # 2 tricks
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
      scores = Minimum.calculate_scores(%Game{}, %{}, taken, 1)
      
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
      scores = Minimum.calculate_scores(%Game{}, %{}, taken, 1)
      
      # Then: Player 1 gets 8 points, others get 0
      assert scores == %{
        1 => 8,  # 8 tricks
        2 => 0,  # 0 tricks
        3 => 0,  # 0 tricks
        4 => 0   # 0 tricks
      }
    end
  end

  describe "handle_deal_over/4" do
    test "scores are correctly calculated at end of deal" do
      # Given: A game in Minimum contract with specific taken cards
      game = %Game{
        id: "test_game",
        players: @players,
        taken: %{1 => [], 2 => [], 3 => [], 4 => []},
        contract_index: @minimum_contract_index,
        dealer_seat: 1,
        scores: %{1 => 10, 2 => 5, 3 => 8, 4 => 12}  # Existing scores
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
      updated_game = Minimum.handle_deal_over(game, hands, taken, 1)
      
      # Then: Scores should reflect Minimum scoring (+1 per trick)
      expected_scores = %{
        1 => 12,  # 10 + 2
        2 => 7,   # 5 + 2
        3 => 10,  # 8 + 2
        4 => 14   # 12 + 2
      }
      
      assert updated_game.scores == expected_scores
      
      # Game state should be updated
      assert is_map(updated_game)
      assert updated_game.scores != game.scores
    end
  end

  describe "can_pass?/2" do
    test "always returns false for Minimum contract" do
      # Given: A game in the Minimum contract
      game = %Game{
        id: "test_game",
        contract_index: @minimum_contract_index
      }
      
      # When/Then: No player can pass
      for seat <- 1..4 do
        refute Minimum.can_pass?(game, seat)
      end
    end
  end

  describe "pass/2" do
    test "returns error for Minimum contract" do
      # Given: A game in the Minimum contract
      game = %Game{
        id: "test_game",
        contract_index: @minimum_contract_index
      }
      
      # When/Then: Attempting to pass returns an error
      assert {:error, "Cannot pass in the Minimum contract"} = Minimum.pass(game, 1)
    end
  end

  describe "integration tests" do
    test "trick winner determination follows standard rules" do
      # Given: A game with a partly completed trick
      game = %Game{
        id: "test_game",
        players: @players,
        contract_index: @minimum_contract_index,
        trick: [
          {1, {:diamonds, 10}},    # Player 1 leads diamonds
          {2, {:diamonds, :king}}, # Player 2 plays higher diamond
          {3, {:diamonds, 7}}      # Player 3 plays lower diamond
        ],
        current_player: 4,
        hands: %{
          1 => [{:clubs, :ace}],
          2 => [{:hearts, 9}],
          3 => [{:spades, 10}],
          4 => [{:diamonds, :ace}] # Player 4 has the highest diamond
        },
        taken: %{1 => [], 2 => [], 3 => [], 4 => []}
      }
      
      # When: Player 4 plays the Ace of Diamonds
      {:ok, updated_game} = Minimum.play_card(game, 4, {:diamonds, :ace}, game.hands)
      
      # Then: Player 4 should win the trick because Ace is highest
      assert updated_game.taken[4] != []
      assert updated_game.current_player == 4 # Winner leads next trick
      
      # And the trick should be in Player 4's taken pile
      trick_cards = List.flatten(updated_game.taken[4])
      assert Enum.member?(trick_cards, {:diamonds, 10})
      assert Enum.member?(trick_cards, {:diamonds, :king})
      assert Enum.member?(trick_cards, {:diamonds, 7})
      assert Enum.member?(trick_cards, {:diamonds, :ace})
    end
    
    test "off-suit plays follow trick-taking rules" do
      # Given: A game where two players can't follow suit
      game = %Game{
        id: "test_game",
        players: @players,
        contract_index: @minimum_contract_index,
        trick: [
          {1, {:clubs, :ace}},    # Player 1 leads with club
          {2, {:clubs, 7}}        # Player 2 follows with club
        ],
        current_player: 3,
        hands: %{
          1 => [{:diamonds, 10}],
          2 => [{:diamonds, :king}],
          3 => [{:hearts, 8}, {:spades, :jack}], # Player 3 has no clubs
          4 => [{:hearts, :king}, {:spades, :ace}] # Player 4 has no clubs
        },
        taken: %{1 => [], 2 => [], 3 => [], 4 => []}
      }
      
      # When: Player 3 and 4 play off-suit cards
      {:ok, game} = Minimum.play_card(game, 3, {:hearts, 8}, game.hands)
      hands = Map.put(game.hands, 3, [{:spades, :jack}])
      game = %{game | hands: hands}
      
      {:ok, updated_game} = Minimum.play_card(game, 4, {:spades, :ace}, game.hands)
      
      # Then: Player 1 should still win the trick (since they led the suit)
      assert updated_game.taken[1] != []
      assert updated_game.current_player == 1 # Winner leads next trick
      
      # And the trick should contain all played cards
      trick_cards = List.flatten(updated_game.taken[1])
      assert Enum.member?(trick_cards, {:clubs, :ace})
      assert Enum.member?(trick_cards, {:clubs, 7})
      assert Enum.member?(trick_cards, {:hearts, 8})
      assert Enum.member?(trick_cards, {:spades, :ace})
    end
  end
end