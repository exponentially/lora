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

  @doc """
  Lists all open games that are waiting for players to join.

  Returns a list of game structs with basic information.
  """
  def list_open_games do
    # Get all active game IDs from supervisor
    game_ids = GameSupervisor.list_games()

    # Fetch the state of each game and filter for those that are still accepting players
    game_ids
    |> Enum.map(fn id ->
      case get_game_state(id) do
        {:ok, game} -> {id, game}
        _ -> nil
      end
    end)
    |> Enum.filter(&(&1 != nil))
    |> Enum.filter(fn {_id, game} ->
      # Games are "open" if they are in lobby phase
      # and have fewer than 4 players
      game.phase == :lobby and length(game.players) < 4
    end)
    |> Enum.map(fn {id, game} ->
      %{
        id: id,
        players: Enum.map(game.players, & &1.name),
        player_count: length(game.players),
        created_at: Map.get(game, :created_at, DateTime.utc_now()),
        creator: List.first(game.players).name
      }
    end)
  end

  @doc """
  Lists all games that a player is actively participating in.

  Returns a list of game structs with basic information.
  """
  def list_player_active_games(player_id) do
    # Get all active game IDs from supervisor
    game_ids = GameSupervisor.list_games()

    # Fetch the state of each game and filter for those containing the player
    game_ids
    |> Enum.map(fn id ->
      case get_game_state(id) do
        {:ok, game} -> {id, game}
        _ -> nil
      end
    end)
    |> Enum.filter(&(&1 != nil))
    |> Enum.filter(fn {_id, game} ->
      # Check if player is in this game
      Enum.any?(game.players, fn p -> p.id == player_id end)
    end)
    |> Enum.map(fn {id, game} ->
      player = Enum.find(game.players, fn p -> p.id == player_id end)

      opponent_names =
        game.players
        |> Enum.reject(fn p -> p.id == player_id end)
        |> Enum.map(& &1.name)

      %{
        id: id,
        players: Enum.map(game.players, & &1.name),
        player_count: length(game.players),
        playing: game.phase != :lobby,
        last_activity:
          Map.get(game, :last_activity, Map.get(game, :created_at, DateTime.utc_now())),
        your_turn:
          Map.get(game, :current_player_idx, nil) ==
            Enum.find_index(game.players, fn p -> p.id == player_id end),
        your_cards: Map.get(player, :hand, []),
        opponents: opponent_names,
        created_at: Map.get(game, :created_at, DateTime.utc_now())
      }
    end)
  end
end
