defmodule Lora.Contracts.QueensTest do
  use ExUnit.Case, async: true
  alias Lora.Game
  alias Lora.Contracts.Queens

  # Define common test data
  @players [
    %{id: "p1", name: "Player 1", seat: 1},
    %{id: "p2", name: "Player 2", seat: 2},
    %{id: "p3", name: "Player 3", seat: 3},
    %{id: "p4", name: "Player 4", seat: 4}
  ]

  @queens_contract_index 2

  describe "is_legal_move?/3" do
    setup do
      # Setup common test data for this describe block
      hands = %{
        1 => [{:clubs, :ace}, {:hearts, :queen}],
        2 => [{:diamonds, :king}, {:clubs, 7}],
        3 => [{:hearts, 8}, {:spades, :queen}],
        4 => [{:spades, :ace}, {:diamonds, :queen}]
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
      assert Queens.is_legal_move?(game, 1, {:clubs, :ace})
      assert Queens.is_legal_move?(game, 1, {:hearts, :queen})
    end

    test "requires following suit when possible", %{game: game} do
      # Given: Player 2 has both clubs and diamonds
      # When: The trick starts with a club
      game_with_trick = %{game | trick: [{1, {:clubs, :ace}}]}
      
      # Then: Player 2 must play a club
      assert Queens.is_legal_move?(game_with_trick, 2, {:clubs, 7})
      refute Queens.is_legal_move?(game_with_trick, 2, {:diamonds, :king})
    end

    test "allows any card when player can't follow suit", %{game: game} do
      # Given: Player 3 has no clubs
      # When: The trick starts with a club
      game_with_trick = %{game | trick: [{1, {:clubs, :ace}}]}
      
      # Then: Player 3 can play any card
      assert Queens.is_legal_move?(game_with_trick, 3, {:hearts, 8})
      assert Queens.is_legal_move?(game_with_trick, 3, {:spades, :queen})
    end
  end

  describe "play_card/4" do
    test "delegates to TrickTaking.play_card" do
      # Given: A game in the Queens contract with empty trick
      game = %Game{
        id: "test_game",
        players: @players,
        trick: [],
        taken: %{1 => [], 2 => [], 3 => [], 4 => []},
        contract_index: @queens_contract_index,
        current_player: 1
      }

      hands = %{
        1 => [{:clubs, :ace}],
        2 => [{:diamonds, :king}],
        3 => [{:hearts, 8}],
        4 => [{:spades, :ace}]
      }

      # When: Player 1 plays a card
      {:ok, updated_game} = Queens.play_card(game, 1, {:clubs, :ace}, hands)
      
      # Then: The trick should be updated and next player's turn
      assert [{1, {:clubs, :ace}}] = updated_game.trick
      assert updated_game.current_player == 2
    end
  end

  describe "calculate_scores/4" do
    test "awards two points per queen taken" do
      # Given: Players have taken tricks with queens
      # Player 1: Queen of Hearts
      # Player 2: Queen of Clubs, Queen of Spades
      # Player 3: No queens
      # Player 4: Queen of Diamonds
      taken = %{
        1 => [
          [{:hearts, :queen}, {:diamonds, :king}, {:clubs, :king}, {:spades, :jack}]
        ],
        2 => [
          [{:clubs, :queen}, {:diamonds, 10}, {:hearts, 10}, {:spades, 9}],
          [{:spades, :queen}, {:diamonds, :jack}, {:hearts, :king}, {:clubs, :jack}]
        ],
        3 => [
          [{:clubs, 10}, {:diamonds, 9}, {:hearts, 8}, {:spades, 7}],
          [{:hearts, 7}, {:diamonds, 8}, {:clubs, 8}, {:spades, 8}]
        ],
        4 => [
          [{:diamonds, :queen}, {:clubs, 9}, {:hearts, 9}, {:spades, 10}],
          [{:hearts, :jack}, {:diamonds, 7}, {:clubs, 7}, {:spades, :ace}]
        ]
      }

      # When: Scores are calculated
      scores = Queens.calculate_scores(%Game{}, %{}, taken, 1)
      
      # Then: Each player gets +2 points per queen taken
      assert scores == %{
        1 => 2,   # 1 queen (hearts) = 2 points
        2 => 4,   # 2 queens (clubs, spades) = 4 points
        3 => 0,   # 0 queens = 0 points
        4 => 2    # 1 queen (diamonds) = 2 points
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
      scores = Queens.calculate_scores(%Game{}, %{}, taken, 1)
      
      # Then: Everyone gets 0 points
      assert scores == %{
        1 => 0,
        2 => 0,
        3 => 0,
        4 => 0
      }
    end

    test "all queens taken by one player" do
      # Given: One player has taken all 4 queens
      taken = %{
        1 => [
          [{:clubs, :queen}, {:diamonds, :king}, {:hearts, :king}, {:spades, :jack}],
          [{:diamonds, :queen}, {:clubs, 10}, {:hearts, 10}, {:spades, 9}],
          [{:hearts, :queen}, {:diamonds, 10}, {:clubs, 9}, {:spades, 8}],
          [{:spades, :queen}, {:diamonds, :jack}, {:hearts, 9}, {:clubs, 8}]
        ],
        2 => [
          [{:clubs, :king}, {:diamonds, 9}, {:hearts, 8}, {:spades, 7}]
        ],
        3 => [
          [{:hearts, :jack}, {:diamonds, 8}, {:clubs, 7}, {:spades, :king}]
        ],
        4 => [
          [{:spades, :ace}, {:diamonds, 7}, {:hearts, 7}, {:clubs, :ace}],
          [{:clubs, :jack}, {:diamonds, :ace}, {:hearts, :ace}, {:spades, 10}]
        ]
      }

      # When: Scores are calculated
      scores = Queens.calculate_scores(%Game{}, %{}, taken, 1)
      
      # Then: Player with all queens gets 8 points, others get 0
      assert scores == %{
        1 => 8,  # 4 queens * 2 points = 8 points
        2 => 0,  # No queens
        3 => 0,  # No queens
        4 => 0   # No queens
      }
    end

    test "correctly identifies queens in nested trick structure" do
      # Given: Complex nested structure with queens in different positions
      taken = %{
        1 => [
          [{:clubs, :ace}, {:diamonds, :queen}, {:hearts, 10}, {:spades, 7}],
          [{:hearts, :ace}, {:clubs, 10}, {:diamonds, 9}, {:spades, 8}]
        ],
        2 => [
          [{:clubs, :queen}, {:hearts, :queen}, {:diamonds, 8}, {:spades, 9}]
        ],
        3 => [],
        4 => [
          [{:spades, :queen}, {:clubs, 9}, {:diamonds, 7}, {:hearts, 7}]
        ]
      }
      
      # When: Scores are calculated
      scores = Queens.calculate_scores(%Game{}, %{}, taken, 1)
      
      # Then: Correct points awarded for queens taken
      assert scores == %{
        1 => 2,  # 1 queen (diamonds) = 2 points
        2 => 4,  # 2 queens (clubs, hearts) = 4 points
        3 => 0,  # No queens
        4 => 2   # 1 queen (spades) = 2 points
      }
    end
  end

  describe "handle_deal_over/4" do
    test "scores are correctly calculated at end of deal" do
      # Given: A game in Queens contract with specific taken cards
      game = %Game{
        id: "test_game",
        players: @players,
        taken: %{1 => [], 2 => [], 3 => [], 4 => []},
        contract_index: @queens_contract_index,
        dealer_seat: 1,
        scores: %{1 => 10, 2 => 5, 3 => 8, 4 => 12}  # Existing scores
      }

      # All hands are empty at end of deal
      hands = %{1 => [], 2 => [], 3 => [], 4 => []}
      
      # Each player has taken different queens
      taken = %{
        1 => [
          [{:hearts, :queen}, {:diamonds, :king}, {:clubs, :king}, {:spades, :jack}]
        ],
        2 => [
          [{:clubs, :queen}, {:diamonds, 10}, {:hearts, 10}, {:spades, 9}]
        ],
        3 => [
          [{:spades, :queen}, {:diamonds, 9}, {:hearts, 8}, {:clubs, 7}]
        ],
        4 => [
          [{:diamonds, :queen}, {:clubs, 9}, {:hearts, 9}, {:spades, 10}]
        ]
      }

      # When: Deal is over
      updated_game = Queens.handle_deal_over(game, hands, taken, 1)
      
      # Then: Scores should reflect Queens scoring (+2 per queen)
      expected_scores = %{
        1 => 12,  # 10 + 2 (1 queen)
        2 => 7,   # 5 + 2 (1 queen)
        3 => 10,  # 8 + 2 (1 queen)
        4 => 14   # 12 + 2 (1 queen)
      }
      
      assert updated_game.scores == expected_scores
      
      # Game state should be updated
      assert is_map(updated_game)
      assert updated_game.scores != game.scores
    end
  end

  describe "can_pass?/2" do
    test "always returns false for Queens contract" do
      # Given: A game in the Queens contract
      game = %Game{
        id: "test_game",
        contract_index: @queens_contract_index
      }
      
      # When/Then: No player can pass
      for seat <- 1..4 do
        refute Queens.can_pass?(game, seat)
      end
    end
  end

  describe "pass/2" do
    test "returns error for Queens contract" do
      # Given: A game in the Queens contract
      game = %Game{
        id: "test_game",
        contract_index: @queens_contract_index
      }
      
      # When/Then: Attempting to pass returns an error
      assert {:error, "Cannot pass in the Queens contract"} = Queens.pass(game, 1)
    end
  end

  describe "integration tests" do
    test "queen taken by player who doesn't win the trick" do
      # Given: A game where a player who doesn't win the trick plays a queen
      game = %Game{
        id: "test_game",
        players: @players,
        contract_index: @queens_contract_index,
        trick: [
          {1, {:diamonds, :ace}},    # Player 1 leads with Ace
          {2, {:diamonds, :queen}},  # Player 2 plays Queen (worth 2 points)
          {3, {:diamonds, 7}}        # Player 3 plays low card
        ],
        current_player: 4,
        hands: %{
          1 => [{:clubs, :ace}],
          2 => [{:hearts, 9}],
          3 => [{:spades, 10}],
          4 => [{:diamonds, :king}]  # Player 4 will play King (not enough to win)
        },
        taken: %{1 => [], 2 => [], 3 => [], 4 => []}
      }
      
      # When: Player 4 plays the King of Diamonds and trick completes
      {:ok, updated_game} = Queens.play_card(game, 4, {:diamonds, :king}, game.hands)
      
      # Then: Player 1 should win the trick because Ace is highest
      assert updated_game.taken[1] != []
      assert updated_game.current_player == 1 # Winner leads next trick
      
      # And Player 1's taken pile should contain the Queen of Diamonds
      trick_cards = List.flatten(updated_game.taken[1])
      assert Enum.member?(trick_cards, {:diamonds, :queen})
      
      # When: Game is over and scores are calculated
      final_game = Queens.handle_deal_over(
        %{updated_game | scores: %{1 => 0, 2 => 0, 3 => 0, 4 => 0}},
        %{1 => [], 2 => [], 3 => [], 4 => []}, 
        updated_game.taken,
        1
      )
      
      # Then: Player 1 should get 2 points for the Queen of Diamonds
      assert final_game.scores[1] == 2
      assert final_game.scores[2] == 0
      assert final_game.scores[3] == 0
      assert final_game.scores[4] == 0
    end
    
    test "queens in different tricks with same winner" do
      # Given: A game where a player takes multiple queens in different tricks
      game = %Game{
        id: "test_game",
        players: @players,
        contract_index: @queens_contract_index,
        hands: %{1 => [], 2 => [], 3 => [], 4 => []},
        taken: %{
          1 => [
            [{:diamonds, :queen}, {:clubs, 9}, {:hearts, 9}, {:spades, 10}],
            [{:hearts, :queen}, {:diamonds, 9}, {:clubs, 8}, {:spades, 9}]
          ],
          2 => [
            [{:clubs, :queen}, {:diamonds, 8}, {:hearts, 8}, {:spades, 8}]
          ],
          3 => [],
          4 => [
            [{:spades, :queen}, {:diamonds, 7}, {:hearts, 7}, {:clubs, 7}]
          ]
        },
        scores: %{1 => 0, 2 => 0, 3 => 0, 4 => 0}
      }
      
      # When: Game is over and scores are calculated
      final_game = Queens.handle_deal_over(game, game.hands, game.taken, 1)
      
      # Then: Scores should reflect queens taken
      assert final_game.scores == %{
        1 => 4,  # 2 queens * 2 points = 4 points
        2 => 2,  # 1 queen * 2 points = 2 points
        3 => 0,  # No queens
        4 => 2   # 1 queen * 2 points = 2 points
      }
    end
  end
end