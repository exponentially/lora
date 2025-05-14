defmodule Lora.Contract do
  @moduledoc """
  Defines the seven contracts of the Lora card game and their scoring rules.
  """

  @type t :: :minimum | :maximum | :queens | :hearts | :jack_of_clubs | :king_hearts_last_trick | :lora

  @contracts [:minimum, :maximum, :queens, :hearts, :jack_of_clubs, :king_hearts_last_trick, :lora]

  @doc """
  Returns all available contracts in their fixed order.
  """
  @spec all :: [t]
  def all, do: @contracts

  @doc """
  Returns the contract at the given index (0-based).
  """
  @spec at(non_neg_integer) :: t
  def at(index) when index >= 0 and index < length(@contracts) do
    Enum.at(@contracts, index)
  end

  @doc """
  Returns the name of the contract for display.
  """
  @spec name(t) :: String.t()
  def name(:minimum), do: "Minimum"
  def name(:maximum), do: "Maximum"
  def name(:queens), do: "Queens"
  def name(:hearts), do: "Hearts"
  def name(:jack_of_clubs), do: "Jack of Clubs"
  def name(:king_hearts_last_trick), do: "King of Hearts + Last Trick"
  def name(:lora), do: "Lora"

  @doc """
  Returns the description of the contract's scoring rules.
  """
  @spec description(t) :: String.t()
  def description(:minimum), do: "Plus one point per trick taken"
  def description(:maximum), do: "Minus one point per trick taken"
  def description(:queens), do: "Plus two points per queen taken"
  def description(:hearts), do: "Plus one point per heart taken; minus eight if one player takes all hearts"
  def description(:jack_of_clubs), do: "Plus eight points to the player who takes it"
  def description(:king_hearts_last_trick), do: "Plus four points each for King of Hearts and Last Trick; plus eight if captured in the same trick"
  def description(:lora), do: "Minus eight to the first player who empties hand; all others receive plus one point per remaining card"

  @doc """
  Returns whether the contract is a trick-taking contract or Lora.
  """
  @spec trick_taking?(t) :: boolean
  def trick_taking?(contract) do
    contract != :lora
  end

  @doc """
  Returns the index of a contract in the fixed order.
  """
  @spec index(t) :: non_neg_integer
  def index(contract) do
    Enum.find_index(@contracts, &(&1 == contract))
  end
end
