defmodule Lora.Contracts.TrickTaking do
  @moduledoc """
  Base module for all trick-taking contracts.
  Contains common logic for handling trick-based gameplay.
  """

  alias Lora.{Game, Deck, Score}

  @doc """
  Common implementation of is_legal_move? for all trick-taking contracts.
  """
  def is_legal_move?(state, seat, {suit, _rank}) do
    hand = state.hands[seat]

    case state.trick do
      # First card in trick can be anything
      [] ->
        true

      # Otherwise must follow suit if possible
      [{_, {led_suit, _}} | _] ->
        if Deck.has_suit?(hand, led_suit) do
          suit == led_suit
        else
          # If no cards of the led suit, can play anything
          true
        end
    end
  end

  @doc """
  Common implementation of play_card for all trick-taking contracts.
  """
  def play_card(state, seat, card, hands) do
    # Add the card to the current trick
    updated_trick = state.trick ++ [{seat, card}]

    # Check if the trick is complete (all 4 players have played)
    if length(updated_trick) == 4 do
      # Determine the winner of the trick
      winner_seat = Deck.trick_winner(updated_trick)

      # Add the cards from the trick to the winner's taken pile
      taken =
        Map.update!(state.taken, winner_seat, fn taken_cards ->
          trick_cards = Enum.map(updated_trick, fn {_seat, card} -> card end)
          taken_cards ++ [trick_cards]
        end)

      # Check if the deal is over (all cards played)
      if Enum.all?(hands, fn {_seat, hand} -> hand == [] end) do
        # Deal is over, calculate scores
        deal_over_state = handle_deal_over(state, hands, taken, winner_seat)
        {:ok, deal_over_state}
      else
        # Continue with the next trick, winner leads
        {:ok, %{state | hands: hands, trick: [], taken: taken, current_player: winner_seat}}
      end
    else
      # Continue with the next player
      next_player = Game.next_seat(seat)
      {:ok, %{state | hands: hands, trick: updated_trick, current_player: next_player}}
    end
  end

  @doc """
  Common implementation of handle_deal_over for trick-taking contracts.
  """
  def handle_deal_over(state, hands, taken, last_trick_winner) do
    # Get the contract module directly using the new approach
    contract_module = Lora.Contract.at(state.contract_index)

    # Calculate scores for this contract
    contract_scores = contract_module.calculate_scores(state, hands, taken, last_trick_winner)

    # Update cumulative scores
    updated_scores = Score.update_cumulative_scores(state.scores, contract_scores)

    # Check if the game is over
    if Game.game_over?(state) do
      %{state | hands: hands, taken: taken, scores: updated_scores, phase: :finished}
    else
      # Move to the next contract or dealer
      {next_dealer, next_contract} = Game.next_dealer_and_contract(state)

      # Deal the next contract
      Game.deal_new_contract(%{
        state
        | dealer_seat: next_dealer,
          contract_index: next_contract,
          scores: updated_scores
      })
    end
  end

  @doc """
  Cannot pass in trick-taking contracts.
  """
  def can_pass?(_state, _seat), do: false

  @doc """
  Passing is not allowed in trick-taking contracts.
  """
  def pass(_state, _seat) do
    {:error, "Cannot pass in trick-taking contracts"}
  end

  @doc """
  Flattens the taken cards structure for scoring.
  Converts %{seat => [[cards]]} to %{seat => [all_cards]}
  """
  def flatten_taken_cards(taken) do
    taken
    |> Map.new(fn {seat, tricks} ->
      {seat, List.flatten(tricks)}
    end)
  end
end
