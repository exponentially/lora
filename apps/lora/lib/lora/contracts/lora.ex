defmodule Lora.Contracts.Lora do
  @moduledoc """
  Implementation of the Lora contract.
  In this contract, the first player to empty their hand scores -8 points,
  and all others score +1 point per card remaining in their hand.
  """

  @behaviour Lora.Contracts.ContractBehaviour

  alias Lora.{Game, Deck, Score}

  @impl true
  def is_legal_move?(state, seat, {suit, rank}) do
    layout = state.lora_layout
    hand = state.hands[seat]

    # If this is the first card played in Lora, any card is legal
    if Enum.all?(layout, fn {_, cards} -> cards == [] end) do
      true
    else
      # Check if card follows layout rules
      suit_layout = layout[suit]

      case suit_layout do
        # No cards of this suit played yet, check if valid starting rank
        [] ->
          # Any card can start a new suit if it's the same rank as a card already on the layout
          any_laid_card =
            layout
            |> Map.values()
            |> List.flatten()
            |> Enum.find(fn _ -> true end)

          case any_laid_card do
            nil -> true  # No cards played yet
            {_, first_rank} -> rank == first_rank  # Must match the first played card's rank
          end

        # Cards of this suit already played, card must be the next in sequence
        cards ->
          {_, last_rank} = List.last(cards)
          rank == Deck.next_rank_lora(last_rank)
      end
    end
  end

  @impl true
  def play_card(state, seat, {suit, rank}, hands) do
    # Add the card to the lora layout
    lora_layout = Map.update!(state.lora_layout, suit, fn cards -> cards ++ [{suit, rank}] end)

    # Check if the player has emptied their hand
    if hands[seat] == [] do
      # This player has won Lora
      deal_over_state = handle_lora_winner(state, hands, seat)
      {:ok, deal_over_state}
    else
      # Find the next player who can play
      {next_player, can_anyone_play} = find_next_player_who_can_play(state, hands, seat)

      if can_anyone_play do
        {:ok, %{state |
          hands: hands,
          lora_layout: lora_layout,
          current_player: next_player
        }}
      else
        # No one can play, the deal is over
        deal_over_state = handle_lora_winner(state, hands, seat)
        {:ok, deal_over_state}
      end
    end
  end

  @impl true
  def calculate_scores(_state, hands, _taken, winner_seat) do
    Score.lora(hands, winner_seat)
  end

  @impl true
  def handle_deal_over(state, hands, _taken, _last_trick_winner) do
    # For Lora, use the player with the fewest cards as the winner
    {winner, _} =
      hands
      |> Enum.min_by(fn {_seat, cards} -> length(cards) end)

    handle_lora_winner(state, hands, winner)
  end

  @impl true
  def can_pass?(state, seat) do
    contract = Lora.Contract.at(state.contract_index)
    contract == :lora && !has_legal_move?(state, seat)
  end

  @impl true
  def pass(state, seat) do
    contract = Lora.Contract.at(state.contract_index)

    cond do
      contract != :lora ->
        {:error, "Can only pass in the Lora contract"}

      has_legal_move?(state, seat) ->
        {:error, "You have legal moves available"}

      true ->
        # Find the next player who can play
        {next_player, can_anyone_play} = find_next_player_who_can_play(state, state.hands, seat)

        if can_anyone_play do
          {:ok, %{state | current_player: next_player}}
        else
          # No one can play, the deal is over - find the player with the fewest cards
          {winner, _} =
            state.hands
            |> Enum.min_by(fn {_seat, cards} -> length(cards) end)

          deal_over_state = handle_lora_winner(state, state.hands, winner)
          {:ok, deal_over_state}
        end
    end
  end

  # Helper functions

  defp has_legal_move?(state, seat) do
    hand = state.hands[seat]
    Enum.any?(hand, &is_legal_move?(state, seat, &1))
  end

  defp find_next_player_who_can_play(state, hands, current_seat) do
    # Try each player in order
    Enum.reduce_while(1..4, {nil, false}, fn _, _ ->
      next_seat = Game.next_seat(current_seat)

      if next_seat == current_seat do
        # We've checked all players and come back to the start
        {:halt, {nil, false}}
      else
        if has_legal_move?(%{state | hands: hands}, next_seat) do
          {:halt, {next_seat, true}}
        else
          {:cont, {nil, false}}
        end
      end
    end)
  end

  defp handle_lora_winner(state, hands, winner_seat) do
    # Calculate Lora scores
    contract_scores = Score.lora(hands, winner_seat)

    # Update cumulative scores
    updated_scores = Score.update_cumulative_scores(state.scores, contract_scores)

    # Check if the game is over
    if Game.game_over?(state) do
      %{state |
        hands: hands,
        scores: updated_scores,
        phase: :finished
      }
    else
      # Move to the next contract or dealer
      {next_dealer, next_contract} = Game.next_dealer_and_contract(state)

      # Deal the next contract
      Game.deal_new_contract(%{state |
        dealer_seat: next_dealer,
        contract_index: next_contract,
        scores: updated_scores
      })
    end
  end
end
