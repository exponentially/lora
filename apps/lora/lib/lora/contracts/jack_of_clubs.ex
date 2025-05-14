defmodule Lora.Contracts.JackOfClubs do
  @moduledoc """
  Implementation of the Jack of Clubs contract.
  In this contract, players score plus eight points if they take the Jack of Clubs.
  """

  @behaviour Lora.Contracts.ContractBehaviour

  alias Lora.{Game, Score}
  alias Lora.Contracts.TrickTaking

  @impl true
  def is_legal_move?(state, seat, card) do
    TrickTaking.is_legal_move?(state, seat, card)
  end

  @impl true
  def play_card(state, seat, card, hands) do
    TrickTaking.play_card(state, seat, card, hands)
  end

  @impl true
  def calculate_scores(_state, _hands, taken, _last_trick_winner) do
    taken
    |> TrickTaking.flatten_taken_cards()
    |> Score.jack_of_clubs()
  end

  @impl true
  def handle_deal_over(state, hands, taken, last_trick_winner) do
    TrickTaking.handle_deal_over(state, hands, taken, last_trick_winner)
  end

  @impl true
  def can_pass?(_state, _seat), do: false

  @impl true
  def pass(_state, _seat) do
    {:error, "Cannot pass in the Jack of Clubs contract"}
  end
end
