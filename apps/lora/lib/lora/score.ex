defmodule Lora.Score do
  @moduledoc """
  Scoring functions for all Lora contracts.
  """

  alias Lora.Deck

  @doc """
  Calculates scores for the Minimum contract.
  Players receive +1 point per trick taken.
  """
  @spec minimum(%{pos_integer => [any]}) :: %{pos_integer => integer}
  def minimum(taken) do
    taken
    |> Map.new(fn {seat, tricks} -> {seat, length(tricks)} end)
  end

  @doc """
  Calculates scores for the Maximum contract.
  Players receive -1 point per trick taken.
  """
  @spec maximum(%{pos_integer => [any]}) :: %{pos_integer => integer}
  def maximum(taken) do
    taken
    |> Map.new(fn {seat, tricks} -> {seat, -1 * length(tricks)} end)
  end

  @doc """
  Calculates scores for the Queens contract.
  Players receive +2 points per queen taken.
  """
  @spec queens(%{pos_integer => [Deck.card()]}) :: %{pos_integer => integer}
  def queens(taken) do
    taken
    |> Map.new(fn {seat, cards} ->
      queens_count = count_cards_by_predicate(cards, &Deck.is_queen?/1)
      {seat, queens_count * 2}
    end)
  end

  @doc """
  Calculates scores for the Hearts contract.
  Players receive +1 point per heart taken.
  If a player takes all hearts, they receive -8 points instead.
  """
  @spec hearts(%{pos_integer => [Deck.card()]}) :: %{pos_integer => integer}
  def hearts(taken) do
    # Count hearts for each player
    hearts_count_by_seat =
      taken
      |> Map.new(fn {seat, cards} ->
        count = count_cards_by_predicate(cards, &Deck.is_heart?/1)
        {seat, count}
      end)

    # Check if any player has all hearts (8 hearts in the deck)
    all_hearts_player =
      hearts_count_by_seat
      |> Enum.find(fn {_seat, count} -> count == 8 end)

    case all_hearts_player do
      {seat, 8} ->
        Map.new(taken, fn {s, _} ->
          if s == seat, do: {s, -8}, else: {s, 0}
        end)

      nil ->
        hearts_count_by_seat
    end
  end

  @doc """
  Calculates scores for the Jack of Clubs contract.
  The player who takes the Jack of Clubs receives +8 points.
  """
  @spec jack_of_clubs(%{pos_integer => [Deck.card()]}) :: %{pos_integer => integer}
  def jack_of_clubs(taken) do
    jack_winner =
      taken
      |> Enum.find(fn {_seat, cards} ->
        Enum.any?(cards, &Deck.is_jack_of_clubs?/1)
      end)

    case jack_winner do
      {seat, _} ->
        Map.new(taken, fn {s, _} ->
          if s == seat, do: {s, 8}, else: {s, 0}
        end)

      nil ->
        Map.new(taken, fn {s, _} -> {s, 0} end)
    end
  end

  @doc """
  Calculates scores for the King of Hearts and Last Trick contract.
  +4 points for the player who takes the King of Hearts.
  +4 points for the player who takes the last trick.
  +8 bonus points if a player takes both in the same trick.
  """
  @spec king_hearts_last_trick(%{pos_integer => [Deck.card()]}, integer) :: %{
          pos_integer => integer
        }
  def king_hearts_last_trick(taken, last_trick_winner) do
    # Find who has the king of hearts
    king_winner =
      taken
      |> Enum.find(fn {_seat, cards} ->
        # Fix: Don't try to use Enum.any? on cards directly, ensure we're working with a list
        cards = List.wrap(cards) |> List.flatten()
        Enum.any?(cards, &Deck.is_king_of_hearts?/1)
      end)

    scores = %{}

    # Score for king of hearts
    scores =
      case king_winner do
        {seat, _} -> Map.put(scores, seat, 4)
        nil -> scores
      end

    # Score for last trick
    scores = Map.update(scores, last_trick_winner, 4, &(&1 + 4))

    # Check if king of hearts was in the last trick for bonus
    king_in_last_trick? =
      case king_winner do
        {seat, _} ->
          # Moved the condition outside the guard clause
          if seat == last_trick_winner do
            taken_cards = Map.get(taken, seat)

            if is_list(taken_cards) and length(taken_cards) > 0 do
              last_trick = List.last(taken_cards)
              is_list(last_trick) && Enum.any?(last_trick, &Deck.is_king_of_hearts?/1)
            else
              false
            end
          else
            false
          end

        _ ->
          false
      end

    # Add bonus if applicable
    scores =
      if king_in_last_trick? do
        Map.update(scores, last_trick_winner, 8, &(&1 + 8))
      else
        scores
      end

    # Ensure all players have a score
    Map.new(taken, fn {seat, _} -> {seat, Map.get(scores, seat, 0)} end)
  end

  @doc """
  Calculates scores for the Lora contract.
  -8 points to the first player who empties their hand.
  +1 point per remaining card for every other player.
  """
  @spec lora(%{pos_integer => [Deck.card()]}, pos_integer) :: %{pos_integer => integer}
  def lora(hands, winner_seat) do
    Map.new(hands, fn {seat, cards} ->
      if seat == winner_seat do
        {seat, -8}
      else
        {seat, length(cards)}
      end
    end)
  end

  @doc false
  @spec count_cards_by_predicate([Deck.card()], (Deck.card() -> boolean)) :: non_neg_integer
  defp count_cards_by_predicate(cards, predicate) do
    Enum.count(cards, predicate)
  end

  @doc """
  Update the cumulative scores with the scores from the current contract.
  """
  @spec update_cumulative_scores(%{pos_integer => integer}, %{pos_integer => integer}) :: %{
          pos_integer => integer
        }
  def update_cumulative_scores(cumulative, current) do
    Map.merge(cumulative, current, fn _k, v1, v2 -> v1 + v2 end)
  end
end
