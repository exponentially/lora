defmodule LoraWeb.GameUtils do
  @moduledoc """
  Utility functions for game mechanics and seating arrangements.
  """

  @doc """
  Calculate the opponent seat positions in a 4-player game based on the current player's seat.

  Returns a map with :top, :left, and :right keys containing the seat numbers.
  For a 4-player card game, the player opposite to you is top, the one on your left is left,
  and the one on your right is right.
  """
  def calculate_opponent_seats(player_seat) do
    # Ensure player_seat is 1, 2, 3, or 4
    seat = if is_integer(player_seat) and player_seat in 1..4, do: player_seat, else: 1

    # Seat calculation for a 4-player card game:
    # For a circular table with players in clockwise order 1,2,3,4
    # If you're player 1, then:
    # - Player 3 is opposite (top)
    # - Player 4 is to your left
    # - Player 2 is to your right

    # Calculate offsets based on player rotation
    # For player in seat 1: top=3, left=4, right=2
    top_offset = 2
    left_offset = 3
    right_offset = 1

    # Calculate the opponent seats with proper modular arithmetic for 1-based indexing
    top = rem(seat - 1 + top_offset, 4) + 1
    left = rem(seat - 1 + left_offset, 4) + 1
    right = rem(seat - 1 + right_offset, 4) + 1

    # Verification of calculations:
    # Player 1: top=3, left=4, right=2
    # Player 2: top=4, left=1, right=3
    # Player 3: top=1, left=2, right=4
    # Player 4: top=2, left=3, right=1

    %{
      top: top,
      left: left,
      right: right
    }
  end

  @doc """
  Find a player's name by seat number.
  """
  def find_player_name(game, seat) do
    game.players
    |> Enum.find(fn p -> p.seat == seat end)
    |> case do
      nil -> "Empty Seat #{seat}"
      player -> player.name
    end
  end
end
