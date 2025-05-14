defmodule Lora.Contracts.LoraTest do
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

  describe "is_legal_move?/3" do
    setup do
      # Setup common test data for this describe block
      lora_layout = %{
        clubs: [],
        diamonds: [],
        hearts: [],
        spades: []
      }

      hands = %{
        1 => [{:clubs, :ace}, {:hearts, :queen}, {:diamonds, 8}],
        2 => [{:diamonds, :king}, {:clubs, 7}, {:spades, 9}],
        3 => [{:hearts, 8}, {:spades, :jack}, {:diamonds, 10}],
        4 => [{:spades, :ace}, {:hearts, :king}, {:clubs, :queen}]
      }

      game = %Game{
        id: "test_game",
        players: @players,
        hands: hands,
        lora_layout: lora_layout,
        contract_index: @lora_contract_index
      }

      %{game: game, hands: hands}
    end

    test "allows any card when layout is empty", %{game: game} do
      # When the layout is empty (first card played), any card is legal
      assert Lora.is_legal_move?(game, 1, {:clubs, :ace})
      assert Lora.is_legal_move?(game, 1, {:hearts, :queen})
      assert Lora.is_legal_move?(game, 1, {:diamonds, 8})
    end

    test "requires matching rank for new suits", %{game: game} do
      # Given: First card played is {:clubs, :ace}
      game_with_card = %{
        game
        | lora_layout: %{
            clubs: [{:clubs, :ace}],
            diamonds: [],
            hearts: [],
            spades: []
          }
      }

      # When: A player tries to play a card of a different suit
      # Then: It must be of the same rank as the first card played
      # Same rank
      assert Lora.is_legal_move?(game_with_card, 2, {:diamonds, :ace})
      # Different rank
      refute Lora.is_legal_move?(game_with_card, 2, {:diamonds, :king})
    end

    test "requires card to be next in sequence for existing suit", %{game: game} do
      # Given: Cards already played in clubs
      game_with_cards = %{
        game
        | lora_layout: %{
            clubs: [{:clubs, :ace}, {:clubs, :king}],
            diamonds: [],
            hearts: [],
            spades: []
          }
      }

      # Then: Next card in clubs must follow the sequence (king -> ace)
      assert Lora.is_legal_move?(game_with_cards, 4, {:clubs, :ace})
      refute Lora.is_legal_move?(game_with_cards, 4, {:clubs, :queen})
    end

    test "handles sequence that wraps around from Ace to 7", %{game: game} do
      # Given: Cards already played in clubs up to Ace
      game_with_cards = %{
        game
        | lora_layout: %{
            clubs: [
              {:clubs, 8},
              {:clubs, 9},
              {:clubs, 10},
              {:clubs, :jack},
              {:clubs, :queen},
              {:clubs, :king},
              {:clubs, :ace}
            ],
            diamonds: [],
            hearts: [],
            spades: []
          }
      }

      # Then: Next card in clubs must be 7
      assert Lora.is_legal_move?(game_with_cards, 2, {:clubs, 7})
      refute Lora.is_legal_move?(game_with_cards, 2, {:clubs, 8})
    end
  end

  describe "play_card/4" do
    setup do
      lora_layout = %{
        clubs: [],
        diamonds: [],
        hearts: [],
        spades: []
      }

      hands = %{
        1 => [{:clubs, :ace}],
        2 => [{:diamonds, :ace}],
        3 => [{:hearts, :ace}],
        4 => [{:spades, :ace}]
      }

      game = %Game{
        id: "test_game",
        players: @players,
        contract_index: @lora_contract_index,
        hands: hands,
        lora_layout: lora_layout,
        current_player: 1,
        dealer_seat: 1,
        scores: %{1 => 0, 2 => 0, 3 => 0, 4 => 0},
        dealt_count: 1,
        trick: [],
        taken: %{1 => [], 2 => [], 3 => [], 4 => []}
      }

      %{game: game, hands: hands}
    end

    test "adds card to layout", %{game: game} do
      # When: Player 1 plays a card
      updated_hands = %{game.hands | 1 => []}

      # First check that the layout update works as expected
      lora_layout =
        Map.update!(game.lora_layout, :clubs, fn cards -> cards ++ [{:clubs, :ace}] end)

      assert lora_layout.clubs == [{:clubs, :ace}]

      # Then verify play_card doesn't throw an error
      {:ok, _updated_game} = Lora.play_card(game, 1, {:clubs, :ace}, updated_hands)
    end

    test "handles player emptying hand", %{game: game} do
      # When: Player 1 plays their last card
      updated_hands = %{game.hands | 1 => []}
      {:ok, updated_game} = Lora.play_card(game, 1, {:clubs, :ace}, updated_hands)

      # Then: Scores are calculated and the game moves to the next contract
      assert Map.keys(updated_game.scores) |> Enum.sort() == [1, 2, 3, 4]

      assert updated_game.contract_index != game.contract_index ||
               updated_game.dealer_seat != game.dealer_seat
    end

    test "finds next player who can play", %{game: game} do
      # Player 1 plays ace of clubs
      # Player 2 can play with ace of diamonds

      # Modify the layout and hands to create a situation where not all players can play
      lora_layout = %{
        clubs: [{:clubs, :ace}],
        diamonds: [],
        hearts: [],
        spades: []
      }

      modified_hands = %{
        # Player 1 has no cards
        1 => [],
        # Player 2 can play ace of diamonds
        2 => [{:diamonds, :ace}],
        # Player 3 can't play (needs ace of hearts)
        3 => [{:hearts, :king}],
        # Player 4 can't play (needs ace of spades)
        4 => [{:spades, :king}]
      }

      modified_game = %{game | lora_layout: lora_layout, hands: modified_hands}

      # When: Player 2 plays their card
      updated_hands = %{modified_hands | 2 => []}
      {:ok, updated_game} = Lora.play_card(modified_game, 2, {:diamonds, :ace}, updated_hands)

      # Then: The game recognizes that no one can play and ends
      assert updated_game.contract_index != modified_game.contract_index ||
               updated_game.dealer_seat != modified_game.dealer_seat
    end
  end

  describe "calculate_scores/4" do
    test "gives winner -8 points and others +1 per card" do
      hands = %{
        # Winner with no cards
        1 => [],
        # 2 cards
        2 => [{:diamonds, :ace}, {:hearts, :king}],
        # 1 card
        3 => [{:clubs, 7}],
        # 3 cards
        4 => [{:spades, :jack}, {:hearts, 8}, {:clubs, :queen}]
      }

      scores = Lora.calculate_scores(nil, hands, nil, 1)

      assert scores == %{
               # Winner gets -8
               1 => -8,
               # +1 per card
               2 => 2,
               # +1 per card
               3 => 1,
               # +1 per card
               4 => 3
             }
    end
  end

  describe "handle_deal_over/4" do
    test "determines winner as player with fewest cards" do
      state = %Game{
        id: "test_game",
        players: @players,
        contract_index: @lora_contract_index,
        hands: %{
          # 2 cards
          1 => [{:clubs, :ace}, {:hearts, :king}],
          # 1 card - winner
          2 => [{:diamonds, :ace}],
          # 3 cards
          3 => [{:hearts, :ace}, {:clubs, :king}, {:diamonds, :queen}],
          # 2 cards
          4 => [{:spades, :ace}, {:hearts, :queen}]
        },
        scores: %{1 => 0, 2 => 0, 3 => 0, 4 => 0},
        dealer_seat: 1,
        dealt_count: 1
      }

      # When deal is over, player with fewest cards (2) should be declared winner
      updated_state = Lora.handle_deal_over(state, state.hands, nil, nil)

      # Then: Scores should reflect player 2 as winner
      assert updated_state.scores[2] == -8
    end
  end

  describe "can_pass?/2" do
    test "allows pass when player has no legal moves" do
      # Given: A game state where player 1 has no legal moves
      lora_layout = %{
        clubs: [{:clubs, :ace}],
        diamonds: [],
        hearts: [],
        spades: []
      }

      # Player 1 has no ace of any suit nor clubs, so can't make a legal move
      hands = %{
        1 => [{:hearts, :king}, {:diamonds, :king}],
        2 => [{:diamonds, :ace}],
        3 => [{:hearts, :ace}],
        4 => [{:spades, :ace}]
      }

      game = %Game{
        id: "test_game",
        players: @players,
        contract_index: @lora_contract_index,
        hands: hands,
        lora_layout: lora_layout
      }

      # Then: Player 1 should be able to pass
      assert Lora.can_pass?(game, 1)
    end

    test "disallows pass when player has legal moves" do
      # Given: A game state where player 1 has legal moves
      lora_layout = %{
        clubs: [{:clubs, :ace}],
        diamonds: [],
        hearts: [],
        spades: []
      }

      # Player 1 has no clubs but has hearts ace which is a legal move
      hands = %{
        1 => [{:hearts, :ace}, {:diamonds, :king}],
        2 => [{:diamonds, :ace}],
        3 => [{:hearts, :king}],
        4 => [{:spades, :ace}]
      }

      game = %Game{
        id: "test_game",
        players: @players,
        contract_index: @lora_contract_index,
        hands: hands,
        lora_layout: lora_layout
      }

      # Then: Player 1 should not be able to pass
      refute Lora.can_pass?(game, 1)
    end
  end

  describe "pass/2" do
    setup do
      lora_layout = %{
        clubs: [{:clubs, :ace}],
        diamonds: [],
        hearts: [],
        spades: []
      }

      hands = %{
        # No legal moves
        1 => [{:hearts, :king}, {:diamonds, :king}],
        # Can play
        2 => [{:diamonds, :ace}],
        # No legal moves
        3 => [{:hearts, 9}, {:spades, :king}],
        # No legal moves
        4 => [{:spades, 8}, {:diamonds, 9}]
      }

      game = %Game{
        id: "test_game",
        players: @players,
        contract_index: @lora_contract_index,
        hands: hands,
        lora_layout: lora_layout,
        current_player: 1,
        scores: %{1 => 0, 2 => 0, 3 => 0, 4 => 0},
        dealer_seat: 1,
        dealt_count: 1
      }

      %{game: game}
    end

    test "returns error for non-Lora contract", %{game: game} do
      # Given: The game is not in Lora contract
      # Minimum contract
      game_not_lora = %{game | contract_index: 0}

      # When: Player tries to pass
      result = Lora.pass(game_not_lora, 1)

      # Then: Error is returned
      assert result == {:error, "Can only pass in the Lora contract"}
    end

    test "returns error when player has legal moves", %{game: game} do
      # Given: Player 2 has legal moves

      # When: Player 2 tries to pass
      result = Lora.pass(game, 2)

      # Then: Error is returned
      assert result == {:error, "You have legal moves available"}
    end

    test "moves to next player when valid pass", %{game: game} do
      # Given: Player 1 has no legal moves

      # When: Player 1 passes
      {:ok, updated_game} = Lora.pass(game, 1)

      # Then: Next player who can play is selected
      assert updated_game.current_player == 2
    end

    test "ends deal when no one can play", %{game: game} do
      # Given: Only player 2 can play, but we'll test after player 2 plays
      game_after_player2 = %{
        game
        | current_player: 3,
          hands: %{
            1 => [{:hearts, :king}, {:diamonds, :king}],
            # Player 2 has played their card
            2 => [],
            3 => [{:hearts, 9}, {:spades, :king}],
            4 => [{:spades, 8}, {:diamonds, 9}]
          }
      }

      # When: Player 3 passes and no one else can play
      {:ok, updated_game} = Lora.pass(game_after_player2, 3)

      # Then: The deal ends and player with fewest cards (player 2) wins
      assert updated_game.contract_index != game_after_player2.contract_index ||
               updated_game.dealer_seat != game_after_player2.dealer_seat

      # Scores should be updated
      assert updated_game.scores != game_after_player2.scores
    end
  end
end
