defmodule Lora.Contract do
  @moduledoc """
  Defines the behavior for contract implementations in the Lora card game.

  Each contract should implement this behavior and provide the required callbacks.
  """

  alias Lora.Game

  # Define the callback specifications that all contracts must implement

  @doc """
  Returns the name of the contract for display.
  """
  @callback name() :: String.t()

  @doc """
  Returns the description of the contract's scoring rules.
  """
  @callback description() :: String.t()

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

  # Contract modules in the fixed order
  @contracts [
    Lora.Contracts.Minimum,
    Lora.Contracts.Maximum,
    Lora.Contracts.Queens,
    Lora.Contracts.Hearts,
    Lora.Contracts.JackOfClubs,
    Lora.Contracts.KingHeartsLastTrick,
    Lora.Contracts.Lora
  ]

  @doc """
  Returns all available contract modules in their fixed order.
  """
  @spec all :: [module()]
  def all, do: @contracts

  @doc """
  Returns the contract module at the given index (0-based).
  """
  @spec at(non_neg_integer) :: module()
  def at(index) when index >= 0 and index < length(@contracts) do
    Enum.at(@contracts, index)
  end

  @doc """
  Returns the name of the contract from the module's callback.
  """
  @spec name(module()) :: String.t()
  def name(contract_module) do
    contract_module.name()
  end

  @doc """
  Returns the description of the contract from the module's callback.
  """
  @spec description(module()) :: String.t()
  def description(contract_module) do
    contract_module.description()
  end
end
