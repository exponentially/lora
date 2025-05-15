defmodule Lora.Contracts.LoraAdditionalTest do
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

  describe "is_legal_move?/3 additional edge cases" do
    test "handles completely empty layout" do
      # Create a game with empty layout
      game = %Game{
        id: "empty_layout_test",
        players: @players,
        lora_layout: %{clubs: [], diamonds: [], hearts: [], spades: []},
        contract_index: @lora_contract_index,
        hands: %{
          1 => [{:hearts, :ace}],
          2 => [{:diamonds, :king}],
          3 => [{:clubs, :queen}],
          4 => [{:spades, :jack}]
        }
      }

      # Any card should be legal on an empty layout
      assert Lora.is_legal_move?(game, 1, {:hearts, :ace})
      assert Lora.is_legal_move?(game, 2, {:diamonds, :king})
    end
  end

  describe "play_card/4 edge cases" do
    test "handles empty hand after play" do
      # Create a base game
      game = %Game{
        id: "empty_hand_test",
        players: @players,
        contract_index: @lora_contract_index,
        lora_layout: %{clubs: [], diamonds: [], hearts: [], spades: []},
        current_player: 1,
        scores: %{1 => 0, 2 => 0, 3 => 0, 4 => 0},
        dealer_seat: 1,
        dealt_count: 1,
        phase: :playing,
        taken: %{1 => [], 2 => [], 3 => [], 4 => []}
      }

      # Play the player's last card
      hands_after = %{
        1 => [], # Empty after play
        2 => [{:diamonds, :king}],
        3 => [{:clubs, :queen}],
        4 => [{:spades, :jack}]
      }

      {:ok, updated_game} = Lora.play_card(game, 1, {:hearts, :ace}, hands_after)

      # Verify the card was added to layout
      assert updated_game.lora_layout.hearts == [{:hearts, :ace}]
    end

    test "handles case where no one can play after current move" do
      # Create a game where no one can make a legal move after this play
      game = %Game{
        id: "no_legal_moves_test",
        players: @players,
        contract_index: @lora_contract_index,
        lora_layout: %{
          clubs: [{:clubs, :ace}],
          diamonds: [{:diamonds, :ace}],
          hearts: [],
          spades: [{:spades, :ace}]
        },
        current_player: 1,
        scores: %{1 => 0, 2 => 0, 3 => 0, 4 => 0},
        dealer_seat: 1,
        dealt_count: 1,
        phase: :playing,
        hands: %{
          1 => [{:hearts, :ace}], # This is the only card that can legally be played
          2 => [{:diamonds, :king}], # No legal moves
          3 => [{:clubs, :king}], # No legal moves
          4 => [{:spades, :king}] # No legal moves
        },
        taken: %{1 => [], 2 => [], 3 => [], 4 => []}
      }

      hands_after = %{
        1 => [], # Empty after play
        2 => [{:diamonds, :king}],
        3 => [{:clubs, :king}],
        4 => [{:spades, :king}]
      }

      {:ok, updated_game} = Lora.play_card(game, 1, {:hearts, :ace}, hands_after)

      # Verify the layout was updated
      assert updated_game.lora_layout.hearts == [{:hearts, :ace}]
    end
  end

  describe "can_pass?/2 edge cases" do
    test "correctly identifies when a player can pass" do
      # Setup a game with the Lora contract where a player has no legal moves
      game = %Game{
        id: "can_pass_test",
        players: @players,
        contract_index: @lora_contract_index,
        lora_layout: %{
          clubs: [{:clubs, :ace}],
          diamonds: [{:diamonds, :ace}],
          hearts: [{:hearts, :ace}],
          spades: [{:spades, :ace}]
        },
        current_player: 1,
        hands: %{
          1 => [{:clubs, :king}, {:hearts, :king}], # No legal moves
          2 => [{:diamonds, :queen}], # Has a legal move
          3 => [{:clubs, :king}], # No legal moves
          4 => [{:spades, :king}] # No legal moves
        }
      }

      # Player 1 should be able to pass (no legal moves)
      assert Lora.can_pass?(game, 1)

      # Player 2 should not be able to pass (has legal moves)
      refute Lora.can_pass?(game, 2)

      # In a different contract, no one should be able to pass
      different_contract_game = %{game | contract_index: 0} # Minimum contract
      refute Lora.can_pass?(different_contract_game, 1)
    end
  end

  describe "pass/2 edge cases" do
    test "returns error when contract is not Lora" do
      # Setup a game with a non-Lora contract
      game = %Game{
        id: "wrong_contract_test",
        players: @players,
        contract_index: 0, # Minimum contract
        current_player: 1
      }

      # Should return an error
      assert {:error, "Can only pass in the Lora contract"} = Lora.pass(game, 1)
    end

    test "returns error when player has legal moves" do
      # Setup a game where the player has legal moves
      game = %Game{
        id: "has_legal_moves_test",
        players: @players,
        contract_index: @lora_contract_index,
        lora_layout: %{clubs: [], diamonds: [], hearts: [], spades: []},
        current_player: 1,
        hands: %{
          1 => [{:hearts, :ace}], # Can play this
          2 => [{:diamonds, :king}],
          3 => [{:clubs, :queen}],
          4 => [{:spades, :jack}]
        }
      }

      # Should return an error because the player has legal moves
      assert {:error, "You have legal moves available"} = Lora.pass(game, 1)
    end
  end
end
