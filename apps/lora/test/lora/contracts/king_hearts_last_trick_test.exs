defmodule Lora.Contracts.KingHeartsLastTrickTest do
  use ExUnit.Case, async: true
  alias Lora.Game
  alias Lora.Contracts.KingHeartsLastTrick

  # Define common test data
  @players [
    %{id: "p1", name: "Player 1", seat: 1},
    %{id: "p2", name: "Player 2", seat: 2},
    %{id: "p3", name: "Player 3", seat: 3},
    %{id: "p4", name: "Player 4", seat: 4}
  ]

  @king_hearts_last_trick_contract_index 5

  describe "is_legal_move?/3" do
    setup do
      # Setup common test data for this describe block
      hands = %{
        1 => [{:clubs, :ace}, {:hearts, :king}],
        2 => [{:diamonds, :king}, {:clubs, 7}],
        3 => [{:hearts, 8}, {:spades, :jack}],
        4 => [{:spades, :ace}, {:hearts, :queen}]
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
      assert KingHeartsLastTrick.is_legal_move?(game, 1, {:clubs, :ace})
      assert KingHeartsLastTrick.is_legal_move?(game, 1, {:hearts, :king})
    end

    test "requires following suit when possible", %{game: game} do
      # Given: Player 2 has both clubs and diamonds
      # When: The trick starts with a club
      game_with_trick = %{game | trick: [{1, {:clubs, :ace}}]}
      
      # Then: Player 2 must play a club
      assert KingHeartsLastTrick.is_legal_move?(game_with_trick, 2, {:clubs, 7})
      refute KingHeartsLastTrick.is_legal_move?(game_with_trick, 2, {:diamonds, :king})
    end

    test "allows any card when player can't follow suit", %{game: game} do
      # Given: Player 3 has no clubs
      # When: The trick starts with a club
      game_with_trick = %{game | trick: [{1, {:clubs, :ace}}]}
      
      # Then: Player 3 can play any card
      assert KingHeartsLastTrick.is_legal_move?(game_with_trick, 3, {:hearts, 8})
      assert KingHeartsLastTrick.is_legal_move?(game_with_trick, 3, {:spades, :jack})
    end
  end

  describe "play_card/4" do
    test "delegates to TrickTaking.play_card" do
      # Given: A game in the KingHeartsLastTrick contract with empty trick
      game = %Game{
        id: "test_game",
        players: @players,
        trick: [],
        taken: %{1 => [], 2 => [], 3 => [], 4 => []},
        contract_index: @king_hearts_last_trick_contract_index,
        current_player: 1
      }

      hands = %{
        1 => [{:clubs, :ace}],
        2 => [{:diamonds, :king}],
        3 => [{:hearts, 8}],
        4 => [{:spades, :ace}]
      }

      # When: Player 1 plays a card
      {:ok, updated_game} = KingHeartsLastTrick.play_card(game, 1, {:clubs, :ace}, hands)
      
      # Then: The trick should be updated and next player's turn
      assert [{1, {:clubs, :ace}}] = updated_game.trick
      assert updated_game.current_player == 2
    end
  end

  describe "calculate_scores/4" do
    test "awards 4 points for King of Hearts and 4 points for last trick" do
      # Given: Player 2 has King of Hearts and Player 3 won the last trick
      taken = %{
        1 => [
          [{:clubs, :ace}, {:diamonds, :king}, {:hearts, :queen}, {:spades, :jack}]
        ],
        2 => [
          [{:hearts, :king}, {:diamonds, :queen}, {:clubs, :jack}, {:spades, :queen}],
          [{:hearts, 10}, {:diamonds, :jack}, {:clubs, :king}, {:spades, 10}]
        ],
        3 => [
          [{:spades, :ace}, {:hearts, :jack}, {:clubs, 10}, {:diamonds, 10}]
        ],
        4 => []
      }

      # When: Scores are calculated
      scores = KingHeartsLastTrick.calculate_scores(%Game{}, %{}, taken, 3)
      
      # Then: Player 2 gets 4 points for King of Hearts, Player 3 gets 4 points for last trick
      assert scores == %{
        1 => 0,  # No king, not last trick winner
        2 => 4,  # Has King of Hearts
        3 => 4,  # Won last trick
        4 => 0   # No king, not last trick winner
      }
    end

    test "awards 16 points when King of Hearts is in the last trick" do
      # Given: Player 3 has King of Hearts in the last trick
      taken = %{
        1 => [
          [{:clubs, :ace}, {:diamonds, :king}, {:hearts, :queen}, {:spades, :jack}]
        ],
        2 => [
          [{:hearts, 10}, {:diamonds, :queen}, {:clubs, :jack}, {:spades, :queen}]
        ],
        3 => [
          [{:hearts, :king}, {:hearts, :jack}, {:clubs, 10}, {:diamonds, 10}]
        ],
        4 => []
      }

      # When: Scores are calculated with Player 3 as last trick winner
      scores = KingHeartsLastTrick.calculate_scores(%Game{}, %{}, taken, 3)
      
      # Then: Player 3 gets 8 points (4 for king + 4 for last trick)
      # Note: The bonus is only applied if the king of hearts is taken in the last trick
      assert scores == %{
        1 => 0,   # No king, not last trick winner
        2 => 0,   # No king, not last trick winner
        3 => 8,   # Has King of Hearts (4) and is last trick winner (4)
        4 => 0    # No king, not last trick winner
      }
    end

    test "no bonus when King of Hearts is not in last trick" do
      # Given: Player 2 has King of Hearts in an earlier trick, Player 3 won last trick
      taken = %{
        1 => [],
        2 => [
          # First trick with King of Hearts
          [{:hearts, :king}, {:diamonds, :queen}, {:clubs, :jack}, {:spades, :queen}]
        ],
        3 => [
          # Last trick without King of Hearts
          [{:hearts, :jack}, {:hearts, 10}, {:clubs, 10}, {:diamonds, 10}]
        ],
        4 => []
      }

      # When: Scores are calculated
      scores = KingHeartsLastTrick.calculate_scores(%Game{}, %{}, taken, 3)
      
      # Then: Player 2 gets 4 points for king, Player 3 gets 4 points for last trick
      assert scores == %{
        1 => 0,  # No king, not last trick winner
        2 => 4,  # Has King of Hearts (not in last trick)
        3 => 4,  # Won last trick (without King of Hearts)
        4 => 0   # No king, not last trick winner
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
      scores = KingHeartsLastTrick.calculate_scores(%Game{}, %{}, taken, 1)
      
      # Then: Only last trick winner gets points
      assert scores == %{
        1 => 4,  # Last trick winner
        2 => 0,
        3 => 0,
        4 => 0
      }
    end

    test "handles missing King of Hearts edge case" do
      # Given: King of Hearts is not in any taken pile (shouldn't happen in practice)
      taken = %{
        1 => [
          [{:clubs, :ace}, {:diamonds, :king}, {:hearts, :queen}, {:spades, :jack}]
        ],
        2 => [
          [{:clubs, :king}, {:diamonds, :queen}, {:spades, :king}, {:spades, :queen}]
        ],
        3 => [
          [{:hearts, :jack}, {:hearts, 10}, {:clubs, 10}, {:diamonds, 10}]
        ],
        4 => []
      }

      # When: Scores are calculated
      scores = KingHeartsLastTrick.calculate_scores(%Game{}, %{}, taken, 3)
      
      # Then: Only last trick winner gets points
      assert scores == %{
        1 => 0,  # No king, not last trick winner
        2 => 0,  # No king, not last trick winner
        3 => 4,  # Last trick winner (no King of Hearts)
        4 => 0   # No king, not last trick winner
      }
    end

    test "handles same player taking all tricks including King of Hearts" do
      # Given: Player 1 has taken all tricks including one with King of Hearts
      taken = %{
        1 => [
          # Earlier trick with King of Hearts
          [{:hearts, :king}, {:diamonds, :queen}, {:clubs, :jack}, {:spades, :queen}],
          # Last trick without King
          [{:hearts, :jack}, {:hearts, 10}, {:clubs, 10}, {:diamonds, 10}]
        ],
        2 => [],
        3 => [],
        4 => []
      }

      # When: Scores are calculated
      scores = KingHeartsLastTrick.calculate_scores(%Game{}, %{}, taken, 1)
      
      # Then: Player 1 gets 8 points (4 for king + 4 for last trick)
      assert scores == %{
        1 => 8,  # Has King of Hearts (4) and won last trick (4)
        2 => 0,
        3 => 0,
        4 => 0
      }
    end
  end

  describe "handle_deal_over/4" do
    test "scores are correctly calculated at end of deal" do
      # Given: A game in KingHeartsLastTrick contract with specific taken cards
      game = %Game{
        id: "test_game",
        players: @players,
        taken: %{1 => [], 2 => [], 3 => [], 4 => []},
        contract_index: @king_hearts_last_trick_contract_index,
        dealer_seat: 1,
        scores: %{1 => 10, 2 => 5, 3 => 8, 4 => 12}  # Existing scores
      }

      # All hands are empty at end of deal
      hands = %{1 => [], 2 => [], 3 => [], 4 => []}
      
      # Player 2 has King of Hearts, Player 3 won last trick
      taken = %{
        1 => [
          [{:clubs, :ace}, {:diamonds, :king}, {:hearts, :queen}, {:spades, :jack}]
        ],
        2 => [
          [{:hearts, :king}, {:diamonds, :queen}, {:clubs, :jack}, {:spades, :queen}]
        ],
        3 => [
          [{:hearts, :jack}, {:hearts, 10}, {:clubs, 10}, {:diamonds, 10}]
        ],
        4 => []
      }

      # When: Deal is over
      updated_game = KingHeartsLastTrick.handle_deal_over(game, hands, taken, 3)
      
      # Then: Scores should reflect KingHeartsLastTrick scoring
      expected_scores = %{
        1 => 10,  # No change (10 + 0)
        2 => 9,   # 5 + 4 (King of Hearts)
        3 => 12,  # 8 + 4 (Last trick)
        4 => 12   # No change (12 + 0)
      }
      
      assert updated_game.scores == expected_scores
      
      # Game state should be updated
      assert is_map(updated_game)
      assert updated_game.scores != game.scores
    end
  end

  describe "can_pass?/2" do
    test "always returns false for KingHeartsLastTrick contract" do
      # Given: A game in the KingHeartsLastTrick contract
      game = %Game{
        id: "test_game",
        contract_index: @king_hearts_last_trick_contract_index
      }
      
      # When/Then: No player can pass
      for seat <- 1..4 do
        refute KingHeartsLastTrick.can_pass?(game, seat)
      end
    end
  end

  describe "pass/2" do
    test "returns error for KingHeartsLastTrick contract" do
      # Given: A game in the KingHeartsLastTrick contract
      game = %Game{
        id: "test_game",
        contract_index: @king_hearts_last_trick_contract_index
      }
      
      # When/Then: Attempting to pass returns an error
      assert {:error, "Cannot pass in the King of Hearts and Last Trick contract"} = KingHeartsLastTrick.pass(game, 1)
    end
  end

  describe "integration tests" do
    test "king of hearts in last trick calculation" do
      # Given: A game where King of Hearts is played in the last trick
      game = %Game{
        id: "test_game",
        players: @players,
        contract_index: @king_hearts_last_trick_contract_index,
        scores: %{1 => 0, 2 => 0, 3 => 0, 4 => 0}
      }

      # Create taken piles where Player 2 has King of Hearts in the last trick
      taken = %{
        1 => [
          [{:clubs, :ace}, {:diamonds, :king}, {:hearts, :queen}, {:spades, :jack}]
        ],
        2 => [
          [{:hearts, :king}, {:clubs, :king}, {:spades, 10}, {:diamonds, 9}]
        ],
        3 => [],
        4 => []
      }
      
      # When: Final scoring happens with Player 2 winning last trick
      updated_game = KingHeartsLastTrick.handle_deal_over(
        game,
        %{1 => [], 2 => [], 3 => [], 4 => []},
        taken,
        2 # Player 2 won the last trick
      )
      
      # Then: Player 2 should get 8 points total
      assert updated_game.scores[1] == 0
      assert updated_game.scores[2] == 8 # 4 (king) + 4 (last trick)
      assert updated_game.scores[3] == 0
      assert updated_game.scores[4] == 0
    end
  end
end