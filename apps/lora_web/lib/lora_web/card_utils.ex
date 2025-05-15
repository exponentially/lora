defmodule LoraWeb.CardUtils do
  @moduledoc """
  Utility functions for formatting cards and providing common styling for the card game UI.
  """

  @doc """
  Formats a card suit to its Unicode symbol.
  """
  def format_suit(:hearts), do: "♥"
  def format_suit(:diamonds), do: "♦"
  def format_suit(:clubs), do: "♣"
  def format_suit(:spades), do: "♠"
  def format_suit(suit), do: suit

  @doc """
  Formats a card rank to a string representation.
  """
  def format_rank(14), do: "A"
  def format_rank(13), do: "K"
  def format_rank(12), do: "Q"
  def format_rank(11), do: "J"
  def format_rank(:ace), do: "A"
  def format_rank(:king), do: "K"
  def format_rank(:queen), do: "Q"
  def format_rank(:jack), do: "J"
  def format_rank(rank), do: "#{rank}"

  @doc """
  Returns the appropriate text color class for a given suit.
  """
  def suit_color(:hearts), do: "text-red-600"
  def suit_color(:diamonds), do: "text-red-600"
  def suit_color(:clubs), do: "text-gray-900"
  def suit_color(:spades), do: "text-gray-900"
end
