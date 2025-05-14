defmodule Lora.Contracts.Hearts do
  @moduledoc """
  Implementation of the Hearts contract.
  In this contract, players score plus one point per heart taken.
  If one player takes all hearts, they get minus eight points.
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
    |> Score.hearts()
  end

  @impl true
  def handle_deal_over(state, hands, taken, last_trick_winner) do
    TrickTaking.handle_deal_over(state, hands, taken, last_trick_winner)
  end

  @impl true
  def can_pass?(_state, _seat), do: false

  @impl true
  def pass(_state, _seat) do
    {:error, "Cannot pass in the Hearts contract"}
  end
end
