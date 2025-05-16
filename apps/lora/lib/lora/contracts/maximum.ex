defmodule Lora.Contracts.Maximum do
  @moduledoc """
  Implementation of the Maximum contract.
  In this contract, players score minus one point per trick taken.
  """

  @behaviour Lora.Contract

  alias Lora.Score
  alias Lora.Contracts.TrickTaking

  @impl true
  def name, do: "Maximum"

  @impl true
  def description, do: "Minus one point per trick taken"

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
    Score.maximum(taken)
  end

  @impl true
  def handle_deal_over(state, hands, taken, last_trick_winner) do
    TrickTaking.handle_deal_over(state, hands, taken, last_trick_winner)
  end

  @impl true
  def can_pass?(_state, _seat), do: false

  @impl true
  def pass(_state, _seat) do
    {:error, "Cannot pass in the Maximum contract"}
  end
end
