defmodule Lora do
  @moduledoc """
  Lora public API for interacting with the game logic.
  """

  alias Lora.{GameServer, GameSupervisor}

  @doc """
  Creates a new game with the specified player as creator and returns its ID.
  """
  def create_game(player_id, player_name) do
    GameSupervisor.create_game(player_id, player_name)
  end

  @doc """
  Joins an existing game.
  """
  def join_game(game_id, player_id, player_name) do
    GameServer.add_player(game_id, player_id, player_name)
  end

  @doc """
  Checks if a game with the given ID exists.
  """
  def game_exists?(game_id) do
    GameSupervisor.game_exists?(game_id)
  end

  @doc """
  Gets the current state of the game.
  """
  def get_game_state(game_id) do
    GameServer.get_state(game_id)
  end

  @doc """
  Adds a player to the game.
  """
  def add_player(game_id, player_id, player_name) do
    GameServer.add_player(game_id, player_id, player_name)
  end

  @doc """
  Plays a card from a player's hand.
  """
  def play_card(game_id, player_id, card) do
    GameServer.play_card(game_id, player_id, card)
  end

  @doc """
  Passes in the Lora contract when a player has no legal moves.
  """
  def pass_lora(game_id, player_id) do
    GameServer.pass_lora(game_id, player_id)
  end

  @doc """
  Handles a player reconnection.
  """
  def player_reconnect(game_id, player_id, pid) do
    GameServer.player_reconnect(game_id, player_id, pid)
  end

  @doc """
  Handles a player disconnection.
  """
  def player_disconnect(game_id, player_id) do
    GameServer.player_disconnect(game_id, player_id)
  end

  @doc """
  Returns legal moves for the current player.
  """
  def legal_moves(game_id, player_id) do
    GameServer.legal_moves(game_id, player_id)
  end

  @doc """
  Generates a random player ID.
  """
  def generate_player_id do
    :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
  end
end
