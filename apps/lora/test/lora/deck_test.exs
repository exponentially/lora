defmodule Lora.DeckTest do
  use ExUnit.Case, async: true

  alias Lora.Deck

  describe "new/0" do
    test "creates a standard 32-card deck" do
      deck = Deck.new()

      # Should have 32 cards
      assert length(deck) == 32

      # Should have 8 cards in each suit
      assert Enum.count(deck, fn {suit, _} -> suit == :clubs end) == 8
      assert Enum.count(deck, fn {suit, _} -> suit == :diamonds end) == 8
      assert Enum.count(deck, fn {suit, _} -> suit == :hearts end) == 8
      assert Enum.count(deck, fn {suit, _} -> suit == :spades end) == 8

      # Should have 4 of each rank
      assert Enum.count(deck, fn {_, rank} -> rank == 7 end) == 4
      assert Enum.count(deck, fn {_, rank} -> rank == 8 end) == 4
      assert Enum.count(deck, fn {_, rank} -> rank == 9 end) == 4
      assert Enum.count(deck, fn {_, rank} -> rank == 10 end) == 4
      assert Enum.count(deck, fn {_, rank} -> rank == :jack end) == 4
      assert Enum.count(deck, fn {_, rank} -> rank == :queen end) == 4
      assert Enum.count(deck, fn {_, rank} -> rank == :king end) == 4
      assert Enum.count(deck, fn {_, rank} -> rank == :ace end) == 4

      # Should have specific cards
      assert Enum.member?(deck, {:hearts, :ace})
      assert Enum.member?(deck, {:clubs, :jack})
      assert Enum.member?(deck, {:diamonds, 10})
      assert Enum.member?(deck, {:spades, 7})
    end
  end

  describe "shuffle/1" do
    test "shuffles the deck" do
      deck = Deck.new()
      shuffled = Deck.shuffle(deck)

      # Same length
      assert length(shuffled) == length(deck)

      # Same cards but different order
      assert Enum.sort(shuffled) == Enum.sort(deck)

      # Extremely low probability they'd be in the same order
      # This test could theoretically fail, but it's very unlikely
      assert shuffled != deck
    end
  end

  describe "deal/2" do
    test "deals cards equally to players" do
      deck = Deck.new()
      hands = Deck.deal(deck, 4)

      # Should have 4 players
      assert map_size(hands) == 4

      # Each player should have 8 cards
      assert length(hands[1]) == 8
      assert length(hands[2]) == 8
      assert length(hands[3]) == 8
      assert length(hands[4]) == 8

      # Cards should be sorted
      assert Enum.all?(hands, fn {_, cards} -> cards == Enum.sort(cards, &Deck.rank_higher?/2) end)

      # All cards should be dealt
      all_dealt_cards = Enum.flat_map(hands, fn {_, cards} -> cards end)
      assert Enum.sort(all_dealt_cards) == Enum.sort(deck)
    end
  end

  describe "trick_winner/1" do
    test "determines the winner of a trick based on the lead suit" do
      # Lead with spades, should win
      trick = [
        {1, {:spades, :king}},
        {2, {:hearts, :ace}},
        {3, {:spades, 10}},
        {4, {:diamonds, :queen}}
      ]

      assert Deck.trick_winner(trick) == 1

      # Another player follows suit with higher card
      trick = [
        {1, {:spades, :king}},
        {2, {:hearts, :ace}},
        {3, {:spades, :ace}},
        {4, {:diamonds, :queen}}
      ]

      assert Deck.trick_winner(trick) == 3
    end
  end

  describe "card helper functions" do
    test "follows_suit?/2 correctly identifies if cards are the same suit" do
      assert Deck.follows_suit?({:hearts, :ace}, {:hearts, 7})
      assert Deck.follows_suit?({:spades, 8}, {:spades, :king})
      refute Deck.follows_suit?({:hearts, :ace}, {:spades, :ace})
    end

    test "has_suit?/2 checks if a hand has cards of a given suit" do
      hand = [{:hearts, :ace}, {:hearts, :king}, {:clubs, 10}, {:spades, 7}]

      assert Deck.has_suit?(hand, :hearts)
      assert Deck.has_suit?(hand, :clubs)
      assert Deck.has_suit?(hand, :spades)
      refute Deck.has_suit?(hand, :diamonds)
    end

    test "cards_of_suit/2 returns all cards of a specified suit" do
      hand = [{:hearts, :ace}, {:hearts, :king}, {:clubs, 10}, {:spades, 7}]

      assert Deck.cards_of_suit(hand, :hearts) == [{:hearts, :ace}, {:hearts, :king}]
      assert Deck.cards_of_suit(hand, :clubs) == [{:clubs, 10}]
      assert Deck.cards_of_suit(hand, :spades) == [{:spades, 7}]
      assert Deck.cards_of_suit(hand, :diamonds) == []
    end

    test "rank_value/1 correctly assigns numerical values to ranks" do
      assert Deck.rank_value(:ace) == 14
      assert Deck.rank_value(:king) == 13
      assert Deck.rank_value(:queen) == 12
      assert Deck.rank_value(:jack) == 11
      assert Deck.rank_value(10) == 10
      assert Deck.rank_value(9) == 9
      assert Deck.rank_value(8) == 8
      assert Deck.rank_value(7) == 7
    end

    test "suit_value/1 correctly assigns numerical values to suits" do
      # Higher values indicate higher sorting priority
      assert Deck.suit_value(:clubs) == 4
      assert Deck.suit_value(:diamonds) == 3
      assert Deck.suit_value(:hearts) == 2
      assert Deck.suit_value(:spades) == 1
    end

    test "rank_higher?/2 correctly compares cards" do
      # Same suit, higher rank wins
      assert Deck.rank_higher?({:hearts, :ace}, {:hearts, :king})
      assert Deck.rank_higher?({:hearts, :king}, {:hearts, :queen})

      # Different suits, suit precedence wins
      assert Deck.rank_higher?({:clubs, 7}, {:diamonds, :ace})
      assert Deck.rank_higher?({:diamonds, 7}, {:hearts, :ace})
      assert Deck.rank_higher?({:hearts, 7}, {:spades, :ace})
    end

    test "special card identification functions" do
      assert Deck.is_queen?({:hearts, :queen})
      assert Deck.is_queen?({:clubs, :queen})
      refute Deck.is_queen?({:hearts, :king})

      assert Deck.is_heart?({:hearts, :ace})
      assert Deck.is_heart?({:hearts, 7})
      refute Deck.is_heart?({:clubs, :ace})

      assert Deck.is_jack_of_clubs?({:clubs, :jack})
      refute Deck.is_jack_of_clubs?({:hearts, :jack})
      refute Deck.is_jack_of_clubs?({:clubs, :queen})

      assert Deck.is_king_of_hearts?({:hearts, :king})
      refute Deck.is_king_of_hearts?({:clubs, :king})
      refute Deck.is_king_of_hearts?({:hearts, :queen})
    end

    test "next_rank_lora/1 returns the next rank in sequence" do
      assert Deck.next_rank_lora(:ace) == 7
      assert Deck.next_rank_lora(:king) == :ace
      assert Deck.next_rank_lora(:queen) == :king
      assert Deck.next_rank_lora(:jack) == :queen
      assert Deck.next_rank_lora(10) == :jack
      assert Deck.next_rank_lora(9) == 10
      assert Deck.next_rank_lora(8) == 9
      assert Deck.next_rank_lora(7) == 8
    end
  end
end
