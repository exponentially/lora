defmodule Lora.Contracts.JackOfClubsTest do
  use ExUnit.Case, async: true
  alias Lora.Game
  alias Lora.Contracts.JackOfClubs

  # Define common test data
  @players [
    %{id: "p1", name: "Player 1", seat: 1},
    %{id: "p2", name: "Player 2", seat: 2},
    %{id: "p3", name: "Player 3", seat: 3},
    %{id: "p4", name: "Player 4", seat: 4}
  ]

  @jack_of_clubs_contract_index 4

  describe "is_legal_move?/3" do
    setup do
      # Setup common test data for this describe block
      hands = %{
        1 => [{:clubs, :ace}, {:hearts, :queen}],
        2 => [{:diamonds, :king}, {:clubs, 7}],
        3 => [{:hearts, 8}, {:spades, :jack}],
        # Player 4 has the Jack of Clubs
        4 => [{:spades, :ace}, {:clubs, :jack}]
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
      assert JackOfClubs.is_legal_move?(game, 1, {:clubs, :ace})
      assert JackOfClubs.is_legal_move?(game, 1, {:hearts, :queen})
    end

    test "requires following suit when possible", %{game: game} do
      # Given: Player 2 has both clubs and diamonds
      # When: The trick starts with a club
      game_with_trick = %{game | trick: [{1, {:clubs, :ace}}]}

      # Then: Player 2 must play a club
      assert JackOfClubs.is_legal_move?(game_with_trick, 2, {:clubs, 7})
      refute JackOfClubs.is_legal_move?(game_with_trick, 2, {:diamonds, :king})
    end

    test "allows any card when player can't follow suit", %{game: game} do
      # Given: Player 3 has no clubs
      # When: The trick starts with a club
      game_with_trick = %{game | trick: [{1, {:clubs, :ace}}]}

      # Then: Player 3 can play any card
      assert JackOfClubs.is_legal_move?(game_with_trick, 3, {:hearts, 8})
      assert JackOfClubs.is_legal_move?(game_with_trick, 3, {:spades, :jack})
    end
  end

  describe "play_card/4" do
    test "delegates to TrickTaking.play_card" do
      # Given: A game in the Jack of Clubs contract with empty trick
      game = %Game{
        id: "test_game",
        players: @players,
        trick: [],
        taken: %{1 => [], 2 => [], 3 => [], 4 => []},
        contract_index: @jack_of_clubs_contract_index,
        current_player: 1
      }

      hands = %{
        1 => [{:clubs, :ace}],
        2 => [{:diamonds, :king}],
        3 => [{:hearts, 8}],
        4 => [{:spades, :ace}]
      }

      # When: Player 1 plays a card
      {:ok, updated_game} = JackOfClubs.play_card(game, 1, {:clubs, :ace}, hands)

      # Then: The trick should be updated and next player's turn
      assert [{1, {:clubs, :ace}}] = updated_game.trick
      assert updated_game.current_player == 2
    end
  end

  describe "calculate_scores/4" do
    test "awards 8 points to the player who takes Jack of Clubs" do
      # Given: Player 2 has taken the Jack of Clubs
      taken = %{
        1 => [
          [{:clubs, :ace}, {:diamonds, :king}, {:hearts, :queen}, {:spades, :jack}]
        ],
        2 => [
          [{:clubs, :jack}, {:diamonds, :queen}, {:hearts, :king}, {:spades, :queen}]
        ],
        3 => [
          [{:hearts, 10}, {:diamonds, :jack}, {:clubs, :king}, {:spades, :ace}]
        ],
        4 => [
          [{:hearts, :jack}, {:diamonds, 10}, {:clubs, 10}, {:spades, 10}]
        ]
      }

      # When: Scores are calculated
      scores = JackOfClubs.calculate_scores(%Game{}, %{}, taken, 1)

      # Then: Player 2 gets 8 points, others get 0
      assert scores == %{
               # No Jack of Clubs
               1 => 0,
               # Has Jack of Clubs
               2 => 8,
               # No Jack of Clubs
               3 => 0,
               # No Jack of Clubs
               4 => 0
             }
    end

    test "handles the case when no one has taken the Jack of Clubs" do
      # Given: No one has the Jack of Clubs (theoretically impossible in a real game)
      taken = %{
        1 => [
          [{:clubs, :ace}, {:diamonds, :king}, {:hearts, :queen}, {:spades, :jack}]
        ],
        2 => [
          [{:clubs, :king}, {:diamonds, :queen}, {:hearts, :king}, {:spades, :queen}]
        ],
        3 => [
          [{:hearts, 10}, {:diamonds, :jack}, {:clubs, :queen}, {:spades, :ace}]
        ],
        4 => [
          [{:hearts, :jack}, {:diamonds, 10}, {:clubs, 10}, {:spades, 10}]
        ]
      }

      # When: Scores are calculated
      scores = JackOfClubs.calculate_scores(%Game{}, %{}, taken, 1)

      # Then: Everyone gets 0 points
      assert scores == %{
               1 => 0,
               2 => 0,
               3 => 0,
               4 => 0
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
      scores = JackOfClubs.calculate_scores(%Game{}, %{}, taken, 1)

      # Then: Everyone gets 0 points
      assert scores == %{
               1 => 0,
               2 => 0,
               3 => 0,
               4 => 0
             }
    end

    test "correctly processes nested trick structure" do
      # Given: Player 3 has Jack of Clubs in a multi-trick structure
      taken = %{
        1 => [
          # First trick with no Jack of Clubs
          [{:hearts, :ace}, {:clubs, :king}, {:diamonds, 10}, {:spades, 7}],
          # Second trick with no Jack of Clubs
          [{:clubs, :ace}, {:diamonds, :king}, {:spades, :queen}, {:hearts, :jack}]
        ],
        2 => [
          # First trick with no Jack of Clubs
          [{:hearts, :king}, {:clubs, :queen}, {:diamonds, :jack}, {:spades, 8}]
        ],
        3 => [
          # First trick with Jack of Clubs
          [{:clubs, :jack}, {:diamonds, 9}, {:hearts, 8}, {:spades, :jack}]
        ],
        # No tricks taken
        4 => []
      }

      # When: Scores are calculated
      scores = JackOfClubs.calculate_scores(%Game{}, %{}, taken, 1)

      # Then: Player 3 gets 8 points, others get 0
      assert scores == %{
               # No Jack of Clubs
               1 => 0,
               # No Jack of Clubs
               2 => 0,
               # Has Jack of Clubs
               3 => 8,
               # No Jack of Clubs
               4 => 0
             }
    end

    test "Jack of Clubs in the last trick" do
      # Given: Jack of Clubs is in the last trick taken by Player 4
      taken = %{
        1 => [
          [{:clubs, :ace}, {:diamonds, :king}, {:hearts, :queen}, {:spades, :jack}]
        ],
        2 => [
          [{:clubs, :king}, {:diamonds, :queen}, {:hearts, :king}, {:spades, :queen}]
        ],
        3 => [
          [{:hearts, 10}, {:diamonds, :jack}, {:clubs, :queen}, {:spades, :ace}]
        ],
        4 => [
          # Last trick with Jack of Clubs
          [{:clubs, :jack}, {:diamonds, 10}, {:hearts, :jack}, {:spades, 10}]
        ]
      }

      # When: Scores are calculated with this as the last trick
      scores = JackOfClubs.calculate_scores(%Game{}, %{}, taken, 4)

      # Then: Player 4 gets 8 points
      assert scores == %{
               1 => 0,
               2 => 0,
               3 => 0,
               # Has Jack of Clubs
               4 => 8
             }
    end
  end

  describe "handle_deal_over/4" do
    test "scores are correctly calculated at end of deal" do
      # Given: A game in Jack of Clubs contract with specific taken cards
      game = %Game{
        id: "test_game",
        players: @players,
        taken: %{1 => [], 2 => [], 3 => [], 4 => []},
        contract_index: @jack_of_clubs_contract_index,
        dealer_seat: 1,
        # Existing scores
        scores: %{1 => 10, 2 => 5, 3 => 8, 4 => 12}
      }

      # All hands are empty at end of deal
      hands = %{1 => [], 2 => [], 3 => [], 4 => []}

      # Player 3 has taken the Jack of Clubs
      taken = %{
        1 => [[{:hearts, :ace}, {:diamonds, :king}, {:clubs, :queen}, {:spades, :jack}]],
        2 => [[{:hearts, :king}, {:diamonds, :ace}, {:spades, :queen}, {:hearts, :queen}]],
        3 => [[{:clubs, :jack}, {:diamonds, :jack}, {:clubs, :ace}, {:spades, :ace}]],
        4 => [[{:hearts, :jack}, {:diamonds, 10}, {:clubs, 10}, {:spades, 10}]]
      }

      # When: Deal is over
      updated_game = JackOfClubs.handle_deal_over(game, hands, taken, 1)

      # Then: Scores should reflect Jack of Clubs scoring
      expected_scores = %{
        # No change (10 + 0)
        1 => 10,
        # No change (5 + 0)
        2 => 5,
        # 8 + 8 (Jack of Clubs)
        3 => 16,
        # No change (12 + 0)
        4 => 12
      }

      assert updated_game.scores == expected_scores

      # Game state should be updated
      assert is_map(updated_game)
      assert updated_game.scores != game.scores
    end
  end

  describe "can_pass?/2" do
    test "always returns false for Jack of Clubs contract" do
      # Given: A game in the Jack of Clubs contract
      game = %Game{
        id: "test_game",
        contract_index: @jack_of_clubs_contract_index
      }

      # When/Then: No player can pass
      for seat <- 1..4 do
        refute JackOfClubs.can_pass?(game, seat)
      end
    end
  end

  describe "pass/2" do
    test "returns error for Jack of Clubs contract" do
      # Given: A game in the Jack of Clubs contract
      game = %Game{
        id: "test_game",
        contract_index: @jack_of_clubs_contract_index
      }

      # When/Then: Attempting to pass returns an error
      assert {:error, "Cannot pass in the Jack of Clubs contract"} = JackOfClubs.pass(game, 1)
    end
  end

  describe "integration tests" do
    test "Jack of Clubs follows trick-taking rules" do
      # Given: A trick where Player 4 plays Jack of Clubs but Player 1 wins with a higher club
      game = %Game{
        id: "test_game",
        players: @players,
        contract_index: @jack_of_clubs_contract_index,
        trick: [
          # Player 1 leads with Ace of Clubs
          {1, {:clubs, :ace}},
          # Player 2 follows with lower club
          {2, {:clubs, 10}},
          # Player 3 follows with lower club
          {3, {:clubs, 7}}
          # Player 4 will play Jack of Clubs
        ],
        hands: %{
          1 => [{:hearts, :king}],
          2 => [{:diamonds, 9}],
          3 => [{:spades, 10}],
          # Jack of Clubs
          4 => [{:clubs, :jack}]
        },
        taken: %{1 => [], 2 => [], 3 => [], 4 => []}
      }

      # When: Player 4 plays Jack of Clubs and the trick completes
      {:ok, updated_game} = JackOfClubs.play_card(game, 4, {:clubs, :jack}, game.hands)

      # Then: Player 1 should win the trick because Ace > Jack
      assert updated_game.taken[1] != []

      # And the Jack of Clubs should be in Player 1's taken pile
      taken_cards = List.flatten(updated_game.taken[1])
      assert Enum.any?(taken_cards, fn card -> card == {:clubs, :jack} end)
    end
  end
end
