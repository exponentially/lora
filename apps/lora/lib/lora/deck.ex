defmodule Lora.Deck do
  @moduledoc """
  Functions for creating and manipulating a 32-card deck for Lora.
  Includes cards A, K, Q, J, 10, 9, 8, 7 in each of the four suits.
  """

  @suits [:clubs, :diamonds, :hearts, :spades]
  @ranks [7, 8, 9, 10, :jack, :queen, :king, :ace]

  @type suit :: :clubs | :diamonds | :hearts | :spades
  @type rank :: 7 | 8 | 9 | 10 | :jack | :queen | :king | :ace
  @type card :: {suit, rank}

  @doc """
  Creates a new, unshuffled 32-card deck.
  """
  @spec new() :: [card]
  def new do
    for suit <- @suits, rank <- @ranks, do: {suit, rank}
  end

  @doc """
  Shuffles the deck using the Fisher-Yates algorithm.
  """
  @spec shuffle([card]) :: [card]
  def shuffle(deck), do: Enum.shuffle(deck)

  @doc """
  Deals cards to players.
  Returns a map of player seat to list of cards.
  """
  @spec deal([card], integer) :: %{pos_integer => [card]}
  def deal(deck, player_count) do
    deck
    |> Enum.with_index()
    |> Enum.reduce(%{}, fn {card, i}, acc ->
      seat = rem(i, player_count) + 1
      Map.update(acc, seat, [card], &[card | &1])
    end)
    |> Map.new(fn {seat, cards} -> {seat, Enum.sort(cards, &rank_higher?/2)} end)
  end

  @doc """
  Returns true if the first card follows the suit of the second card.
  """
  @spec follows_suit?(card, card) :: boolean
  def follows_suit?({suit, _}, {suit, _}), do: true
  def follows_suit?(_, _), do: false

  @doc """
  Returns true if the player has any cards of the given suit.
  """
  @spec has_suit?([card], suit) :: boolean
  def has_suit?(hand, suit) do
    Enum.any?(hand, fn {card_suit, _} -> card_suit == suit end)
  end

  @doc """
  Returns all cards of the specified suit from the hand.
  """
  @spec cards_of_suit([card], suit) :: [card]
  def cards_of_suit(hand, suit) do
    Enum.filter(hand, fn {card_suit, _} -> card_suit == suit end)
  end

  @doc """
  Determines the winner of a trick.
  """
  @spec trick_winner([{integer, card}]) :: integer
  def trick_winner(trick) do
    [{first_seat, {led_suit, _}} | _] = trick

    {winner_seat, _} =
      Enum.reduce(trick, {first_seat, -1}, fn {seat, {suit, rank}}, {current_winner, highest_value} ->
        if suit == led_suit do
          rank_value = rank_value(rank)
          if rank_value > highest_value, do: {seat, rank_value}, else: {current_winner, highest_value}
        else
          {current_winner, highest_value}
        end
      end)

    winner_seat
  end

  @doc """
  Returns the numerical value of a rank for comparison.
  """
  @spec rank_value(rank) :: integer
  def rank_value(:ace), do: 14
  def rank_value(:king), do: 13
  def rank_value(:queen), do: 12
  def rank_value(:jack), do: 11
  def rank_value(rank) when is_integer(rank), do: rank

  @doc """
  Determines if the first card ranks higher than the second card.
  Used for sorting cards in hand.
  """
  @spec rank_higher?(card, card) :: boolean
  def rank_higher?({suit1, rank1}, {suit2, rank2}) do
    case {suit1, suit2} do
      {same, same} -> rank_value(rank1) > rank_value(rank2)
      {s1, s2} -> suit_value(s1) > suit_value(s2)
    end
  end

  @doc """
  Returns a numerical value for suit ordering.
  """
  @spec suit_value(suit) :: integer
  def suit_value(:clubs), do: 4
  def suit_value(:diamonds), do: 3
  def suit_value(:hearts), do: 2
  def suit_value(:spades), do: 1

  @doc """
  Returns true if the card is a queen.
  """
  @spec is_queen?(card) :: boolean
  def is_queen?({_, :queen}), do: true
  def is_queen?(_), do: false

  @doc """
  Returns true if the card is a heart.
  """
  @spec is_heart?(card) :: boolean
  def is_heart?({:hearts, _}), do: true
  def is_heart?(_), do: false

  @doc """
  Returns true if the card is the jack of clubs.
  """
  @spec is_jack_of_clubs?(card) :: boolean
  def is_jack_of_clubs?({:clubs, :jack}), do: true
  def is_jack_of_clubs?(_), do: false

  @doc """
  Returns true if the card is the king of hearts.
  """
  @spec is_king_of_hearts?(card) :: boolean
  def is_king_of_hearts?({:hearts, :king}), do: true
  def is_king_of_hearts?(_), do: false

  @doc """
  Determines the next rank in the sequence for the Lora contract.
  For standard ranks: rank, rank+1, ..., King, Ace, 7, 8, ...
  """
  @spec next_rank_lora(rank) :: rank
  def next_rank_lora(:ace), do: 7
  def next_rank_lora(:king), do: :ace
  def next_rank_lora(:queen), do: :king
  def next_rank_lora(:jack), do: :queen
  def next_rank_lora(10), do: :jack
  def next_rank_lora(9), do: 10
  def next_rank_lora(8), do: 9
  def next_rank_lora(7), do: 8
end
