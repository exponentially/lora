defmodule Lora.Contracts.KingHeartsLastTrick do
  @moduledoc """
  Implementation of the King of Hearts and Last Trick contract.
  In this contract, players score plus four points each for King of Hearts and Last Trick;
  plus eight if captured in the same trick.
  """

  @behaviour Lora.Contract

  alias Lora.Score
  alias Lora.Contracts.TrickTaking

  @impl true
  def name, do: "King of Hearts + Last Trick"

  @impl true
  def description,
    do:
      "Plus four points each for King of Hearts and Last Trick; plus eight if captured in the same trick"

  @impl true
  def is_legal_move?(state, seat, card) do
    TrickTaking.is_legal_move?(state, seat, card)
  end

  @impl true
  def play_card(state, seat, card, hands) do
    TrickTaking.play_card(state, seat, card, hands)
  end

  @impl true
  def calculate_scores(_state, _hands, taken, last_trick_winner) do
    taken
    |> TrickTaking.flatten_taken_cards()
    |> Score.king_hearts_last_trick(last_trick_winner)
  end

  @impl true
  def handle_deal_over(state, hands, taken, last_trick_winner) do
    TrickTaking.handle_deal_over(state, hands, taken, last_trick_winner)
  end

  @impl true
  def can_pass?(_state, _seat), do: false

  @impl true
  def pass(_state, _seat) do
    {:error, "Cannot pass in the King of Hearts and Last Trick contract"}
  end
end
