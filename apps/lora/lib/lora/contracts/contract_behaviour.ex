defmodule Lora.Contracts.ContractBehaviour do
  @moduledoc """
  Behaviour that all contract implementations must follow.
  Defines the common interface for handling game contracts.
  """

  alias Lora.Game

  @doc """
  Check if a move is legal in the context of this contract.
  """
  @callback is_legal_move?(Game.t(), integer(), Lora.Deck.card()) :: boolean()

  @doc """
  Handle a card being played in this contract.
  """
  @callback play_card(Game.t(), integer(), Lora.Deck.card(), map()) :: {:ok, Game.t()}

  @doc """
  Calculate scores at the end of a contract.
  """
  @callback calculate_scores(Game.t(), map(), map(), integer()) :: map()

  @doc """
  Handle the end of a contract.
  """
  @callback handle_deal_over(Game.t(), map(), map(), integer()) :: Game.t()

  @doc """
  Check if a passing action is legal for this contract.
  """
  @callback can_pass?(Game.t(), integer()) :: boolean()

  @doc """
  Handle a pass action.
  """
  @callback pass(Game.t(), integer()) :: {:ok, Game.t()} | {:error, binary()}
end
