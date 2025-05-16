defmodule Lora.Contracts.HeartsTest do
  use ExUnit.Case, async: true
  alias Lora.Game
  alias Lora.Contracts.Hearts

  # Define common test data
  @players [
    %{id: "p1", name: "Player 1", seat: 1},
    %{id: "p2", name: "Player 2", seat: 2},
    %{id: "p3", name: "Player 3", seat: 3},
    %{id: "p4", name: "Player 4", seat: 4}
  ]

  @hearts_contract_index 3

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
      assert Hearts.is_legal_move?(game, 1, {:clubs, :ace})
      assert Hearts.is_legal_move?(game, 1, {:hearts, :queen})
    end

    test "requires following suit when possible", %{game: game} do
      # Given: Player 2 has both clubs and diamonds
      # When: The trick starts with a club
      game_with_trick = %{game | trick: [{1, {:clubs, :ace}}]}

      # Then: Player 2 must play a club
      assert Hearts.is_legal_move?(game_with_trick, 2, {:clubs, 7})
      refute Hearts.is_legal_move?(game_with_trick, 2, {:diamonds, :king})
    end

    test "allows any card when player can't follow suit", %{game: game} do
      # Given: Player 3 has no clubs
      # When: The trick starts with a club
      game_with_trick = %{game | trick: [{1, {:clubs, :ace}}]}

      # Then: Player 3 can play any card
      assert Hearts.is_legal_move?(game_with_trick, 3, {:hearts, 8})
      assert Hearts.is_legal_move?(game_with_trick, 3, {:spades, :jack})
    end
  end

  describe "play_card/4" do
    test "delegates to TrickTaking.play_card" do
      # Given: A game in the Hearts contract with empty trick
      game = %Game{
        id: "test_game",
        players: @players,
        trick: [],
        taken: %{1 => [], 2 => [], 3 => [], 4 => []},
        contract_index: @hearts_contract_index,
        current_player: 1
      }

      hands = %{
        1 => [{:clubs, :ace}],
        2 => [{:diamonds, :king}],
        3 => [{:hearts, 8}],
        4 => [{:spades, :ace}]
      }

      # When: Player 1 plays a card
      {:ok, updated_game} = Hearts.play_card(game, 1, {:clubs, :ace}, hands)

      # Then: The trick should be updated and next player's turn
      assert [{1, {:clubs, :ace}}] = updated_game.trick
      assert updated_game.current_player == 2
    end
  end

  describe "calculate_scores/4" do
    # Helper function to create taken cards structure for testing
    defp create_taken_with_hearts(hearts_distribution) do
      # Convert the simple map of seat->heart count to the nested taken structure
      hearts_distribution
      |> Map.new(fn {seat, heart_count} ->
        heart_cards =
          if heart_count > 0 do
            # Create tricks with appropriate number of hearts
            hearts =
              Enum.map(1..heart_count, fn i ->
                rank =
                  cond do
                    i == 1 -> :ace
                    i == 2 -> :king
                    i == 3 -> :queen
                    i == 4 -> :jack
                    # 10, 9, 8, 7 for i=5,6,7,8
                    true -> 14 - i
                  end

                {:hearts, rank}
              end)

            # Fill in with non-heart cards for 4-card tricks
            hearts_per_trick = Enum.chunk_every(hearts, 1)

            tricks =
              Enum.map(hearts_per_trick, fn [heart] ->
                [heart, {:clubs, 8}, {:diamonds, 8}, {:spades, 8}]
              end)

            tricks
          else
            []
          end

        {seat, heart_cards}
      end)
    end

    test "awards one point per heart taken" do
      # Given: Players who have taken various heart cards
      # Player 1: hearts ace, king (2 hearts)
      # Player 2: hearts queen (1 heart)
      # Player 3: hearts 10 (1 heart) 
      # Player 4: hearts jack, 8 (2 hearts)
      taken = %{
        1 => [
          [{:hearts, :ace}, {:diamonds, :king}, {:clubs, :queen}, {:spades, :jack}],
          [{:hearts, :king}, {:diamonds, :ace}, {:clubs, :king}, {:spades, :queen}]
        ],
        2 => [
          [{:hearts, :queen}, {:diamonds, :queen}, {:clubs, :jack}, {:spades, :king}]
        ],
        3 => [
          [{:hearts, 10}, {:diamonds, :jack}, {:clubs, :ace}, {:spades, :ace}]
        ],
        4 => [
          [{:hearts, :jack}, {:diamonds, 10}, {:clubs, 10}, {:spades, 10}],
          [{:hearts, 8}, {:diamonds, 8}, {:clubs, 8}, {:spades, 8}]
        ]
      }

      # When: Scores are calculated
      scores = Hearts.calculate_scores(%Game{}, %{}, taken, 1)

      # Then: Each player should get 1 point per heart taken
      assert scores == %{
               # 2 hearts
               1 => 2,
               # 1 heart
               2 => 1,
               # 1 heart
               3 => 1,
               # 2 hearts
               4 => 2
             }
    end

    test "awards -8 points if one player takes all hearts" do
      # Given: Player 1 has taken all 8 hearts in the deck
      taken = %{
        1 => [
          # All 8 hearts spread across tricks
          [{:hearts, :ace}, {:diamonds, :king}, {:clubs, :queen}, {:spades, :jack}],
          [{:hearts, :king}, {:diamonds, :ace}, {:clubs, :king}, {:spades, :queen}],
          [{:hearts, :queen}, {:diamonds, :queen}, {:clubs, :jack}, {:spades, :king}],
          [{:hearts, :jack}, {:diamonds, :jack}, {:clubs, :ace}, {:spades, :ace}],
          [{:hearts, 10}, {:diamonds, 10}, {:clubs, 10}, {:spades, 10}],
          [{:hearts, 9}, {:diamonds, 9}, {:clubs, 9}, {:spades, 9}],
          [{:hearts, 8}, {:diamonds, 8}, {:clubs, 8}, {:spades, 8}],
          [{:hearts, 7}, {:diamonds, 7}, {:clubs, 7}, {:spades, 7}]
        ],
        # No tricks won
        2 => [],
        # No tricks won
        3 => [],
        # No tricks won
        4 => []
      }

      # When: Scores are calculated
      scores = Hearts.calculate_scores(%Game{}, %{}, taken, 1)

      # Then: Player 1 gets -8, others get 0
      assert scores == %{
               # All hearts penalty
               1 => -8,
               # No hearts
               2 => 0,
               # No hearts
               3 => 0,
               # No hearts
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
      scores = Hearts.calculate_scores(%Game{}, %{}, taken, 1)

      # Then: Everyone gets 0 points
      assert scores == %{
               1 => 0,
               2 => 0,
               3 => 0,
               4 => 0
             }
    end

    test "works when hearts are distributed among players" do
      # Given: Each player has taken a specific number of hearts
      # Player 1: Ace of hearts (1 heart)
      # Player 2: King of hearts (1 heart)
      # Player 3: Queen and Jack of hearts (2 hearts)
      # Player 4: 10, 9, 8, 7 of hearts (4 hearts)
      taken = %{
        1 => [[{:hearts, :ace}, {:diamonds, :king}, {:clubs, :queen}, {:spades, :jack}]],
        2 => [[{:hearts, :king}, {:diamonds, :ace}, {:clubs, :king}, {:spades, :queen}]],
        3 => [[{:hearts, :queen}, {:hearts, :jack}, {:clubs, :jack}, {:spades, :king}]],
        4 => [[{:hearts, 10}, {:hearts, 9}, {:hearts, 8}, {:hearts, 7}]]
      }

      # When: Scores are calculated
      scores = Hearts.calculate_scores(%Game{}, %{}, taken, 1)

      # Then: Each player gets points equal to hearts taken
      assert scores == %{
               # 1 heart
               1 => 1,
               # 1 heart
               2 => 1,
               # 2 hearts
               3 => 2,
               # 4 hearts
               4 => 4
             }
    end

    test "handles fewer than 8 hearts in play" do
      # Given: Only 7 hearts in play (one heart missing)
      taken =
        create_taken_with_hearts(%{
          # Player 1 has 3 hearts
          1 => 3,
          # Player 2 has 2 hearts
          2 => 2,
          # Player 3 has 2 hearts
          3 => 2,
          # Player 4 has no hearts
          4 => 0
        })

      # When: Scores are calculated
      scores = Hearts.calculate_scores(%Game{}, %{}, taken, 1)

      # Then: Normal scoring applies (no -8 special case)
      assert scores == %{
               1 => 3,
               2 => 2,
               3 => 2,
               4 => 0
             }
    end

    test "correctly processes nested trick structure" do
      # Given: A complex nested structure with multiple tricks per player
      taken = %{
        1 => [
          # First trick with one heart
          [{:hearts, :ace}, {:clubs, :king}, {:diamonds, 10}, {:spades, 7}],
          # Second trick with no hearts
          [{:clubs, :ace}, {:diamonds, :king}, {:spades, :queen}, {:clubs, :jack}]
        ],
        2 => [
          # First trick with two hearts
          [{:hearts, :king}, {:hearts, :queen}, {:diamonds, :jack}, {:spades, 8}]
        ],
        # No tricks taken
        3 => [],
        4 => [
          # First trick with no hearts
          [{:clubs, 10}, {:diamonds, 9}, {:spades, :jack}, {:clubs, 7}],
          # Second trick with one heart
          [{:hearts, 10}, {:clubs, 9}, {:diamonds, 7}, {:spades, 10}]
        ]
      }

      # When: Scores are calculated
      scores = Hearts.calculate_scores(%Game{}, %{}, taken, 1)

      # Then: Points should reflect heart counts after flattening
      assert scores == %{
               # 1 heart (ace)
               1 => 1,
               # 2 hearts (king, queen)
               2 => 2,
               # 0 hearts (no tricks taken)
               3 => 0,
               # 1 heart (10)
               4 => 1
             }
    end

    test "handles invalid or unexpected data gracefully" do
      # Given: A malformed taken structure (nested more deeply than expected)
      # This tests robustness against potential data corruption
      taken = %{
        1 => [
          # Extra nesting level
          [
            [{:hearts, :ace}, {:clubs, :king}, {:diamonds, 10}, {:spades, 7}]
          ]
        ],
        2 => [[{:hearts, :king}, {:clubs, 10}, {:diamonds, :queen}, {:spades, :jack}]],
        3 => [],
        4 => []
      }

      # When/Then: Should not crash when calculating scores
      # The function might not correctly count hearts in this case, but it should at least not crash
      # We'll just run it and make sure we get some kind of result
      result = Hearts.calculate_scores(%Game{}, %{}, taken, 1)
      assert is_map(result)
    end
  end

  describe "handle_deal_over/4" do
    test "scores are correctly calculated at end of deal" do
      # Given: A game in Hearts contract with specific taken cards
      game = %Game{
        id: "test_game",
        players: @players,
        taken: %{1 => [], 2 => [], 3 => [], 4 => []},
        contract_index: @hearts_contract_index,
        dealer_seat: 1,
        scores: %{1 => 0, 2 => 0, 3 => 0, 4 => 0}
      }

      # All hands are empty at end of deal
      hands = %{1 => [], 2 => [], 3 => [], 4 => []}

      # Each player has taken 1 heart
      taken = %{
        1 => [[{:hearts, :ace}, {:diamonds, :king}, {:clubs, :queen}, {:spades, :jack}]],
        2 => [[{:hearts, :king}, {:diamonds, :ace}, {:clubs, :king}, {:spades, :queen}]],
        3 => [[{:hearts, :queen}, {:diamonds, :jack}, {:clubs, :ace}, {:spades, :ace}]],
        4 => [[{:hearts, :jack}, {:diamonds, 10}, {:clubs, 10}, {:spades, 10}]]
      }

      # When: Deal is over
      updated_game = Hearts.handle_deal_over(game, hands, taken, 1)

      # Then: Scores should reflect hearts taken
      expected_scores = %{
        # Ace of hearts
        1 => 1,
        # King of hearts
        2 => 1,
        # Queen of hearts
        3 => 1,
        # Jack of hearts
        4 => 1
      }

      assert updated_game.scores == expected_scores

      # Game state should be updated
      assert is_map(updated_game)
      assert updated_game.scores != game.scores
    end
  end

  describe "can_pass?/2" do
    test "always returns false for Hearts contract" do
      # Given: A game in the Hearts contract
      game = %Game{
        id: "test_game",
        contract_index: @hearts_contract_index
      }

      # When/Then: No player can pass
      for seat <- 1..4 do
        refute Hearts.can_pass?(game, seat)
      end
    end
  end

  describe "integration tests" do
    test "hearts scores integrate with game progression" do
      # Given: A game nearing the end of a hearts deal
      game = %Game{
        id: "test_game",
        players: @players,
        contract_index: @hearts_contract_index,
        dealer_seat: 1,
        # Existing scores from previous deals
        scores: %{1 => 10, 2 => 5, 3 => 8, 4 => 12},
        taken: %{
          1 => [[{:hearts, :ace}, {:clubs, :king}, {:diamonds, 10}, {:spades, 7}]],
          2 => [[{:hearts, :king}, {:clubs, 10}, {:diamonds, :queen}, {:spades, :jack}]],
          3 => [[{:hearts, :queen}, {:clubs, :ace}, {:diamonds, :jack}, {:spades, 9}]],
          4 => [[{:hearts, :jack}, {:clubs, 9}, {:diamonds, 8}, {:spades, 8}]]
        }
      }

      # Empty hands indicate deal is over
      hands = %{1 => [], 2 => [], 3 => [], 4 => []}

      # When: Deal is over and final scoring occurs
      updated_game = Hearts.handle_deal_over(game, hands, game.taken, 1)

      # Then: Hearts scores should be added to existing scores
      # Previous scores: %{1 => 10, 2 => 5, 3 => 8, 4 => 12}
      # Hearts taken: 1 per player
      assert updated_game.scores == %{
               # 10 + 1
               1 => 11,
               # 5 + 1
               2 => 6,
               # 8 + 1
               3 => 9,
               # 12 + 1
               4 => 13
             }
    end

    test "hearts contract respects trick winning rules" do
      # Given: A trick where player 1 plays a heart but player 2 wins with a higher card of the led suit
      game = %Game{
        id: "test_game",
        players: @players,
        contract_index: @hearts_contract_index,
        trick: [
          # Player 1 leads clubs
          {1, {:clubs, :jack}},
          # Player 2 plays higher club
          {2, {:clubs, :ace}},
          # Player 3 plays off-suit (heart)
          {3, {:hearts, :king}}
        ],
        current_player: 4,
        hands: %{
          # Players still have cards (deal not over)
          1 => [{:diamonds, 8}],
          2 => [{:diamonds, 9}],
          3 => [{:diamonds, 10}],
          4 => [{:clubs, 7}]
        },
        taken: %{1 => [], 2 => [], 3 => [], 4 => []}
      }

      # When: The trick is completed by player 4
      {:ok, updated_game} =
        Hearts.play_card(
          game,
          4,
          {:clubs, 7},
          game.hands
        )

      # Then: Player 2 should win the trick because they played highest club
      trick_cards = List.flatten(updated_game.taken[2])
      assert length(trick_cards) == 4
      # And the hearts should be included in the trick
      assert Enum.any?(trick_cards, fn {suit, _} -> suit == :hearts end)
    end
  end

  describe "pass/2" do
    test "returns error for Hearts contract" do
      # Given: A game in the Hearts contract
      game = %Game{
        id: "test_game",
        contract_index: @hearts_contract_index
      }

      # When/Then: Attempting to pass returns an error
      assert {:error, "Cannot pass in the Hearts contract"} = Hearts.pass(game, 1)
    end
  end
end
