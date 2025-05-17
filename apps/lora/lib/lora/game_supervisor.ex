defmodule Lora.GameSupervisor do
  @moduledoc """
  Supervisor for Lora.GameServer processes.
  Creates and monitors game server processes.
  """

  use DynamicSupervisor
  alias Lora.GameServer

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @doc """
  Lists all active game IDs by querying the registry.
  """
  def list_games do
    Registry.select(Lora.GameRegistry, [{{:"$1", :_, :_}, [], [:"$1"]}])
  end

  @doc """
  Creates a new game with a random 6-character ID and starts its server.
  Also adds the creator as the first player.
  """
  def create_game(player_id, player_name) do
    # Generate a random 6-character game ID
    game_id = generate_game_id()

    # Start the game server
    case start_game(game_id) do
      {:ok, _pid} ->
        # Add the creator as the first player
        case GameServer.add_player(game_id, player_id, player_name) do
          {:ok, _game} -> {:ok, game_id}
          error -> error
        end

      error ->
        error
    end
  end

  @doc """
  Creates a game with a specific ID and starts its server.
  Also adds the creator as the first player.
  Used primarily for testing or when a specific ID is needed.
  """
  def create_game_with_id(game_id, player_id, player_name) do
    case start_game(game_id) do
      {:ok, _pid} ->
        # Add the creator as the first player
        case GameServer.add_player(game_id, player_id, player_name) do
          {:ok, _game} -> {:ok, game_id}
          error -> error
        end

      error ->
        error
    end
  end

  @doc """
  Starts a game server for the given game ID.
  """
  def start_game(game_id) do
    DynamicSupervisor.start_child(__MODULE__, {GameServer, game_id})
  end

  @doc """
  Stops a game server for the given game ID.
  """
  def stop_game(game_id) do
    case Registry.lookup(Lora.GameRegistry, game_id) do
      [{pid, _}] ->
        DynamicSupervisor.terminate_child(__MODULE__, pid)

      [] ->
        {:error, :not_found}
    end
  end

  @doc """
  Checks if a game with the given ID exists.
  """
  def game_exists?(game_id) do
    case Registry.lookup(Lora.GameRegistry, game_id) do
      [] -> false
      _ -> true
    end
  end

  @doc """
  Generates a random 6-character game ID.
  """
  def generate_game_id do
    characters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"

    1..6
    |> Enum.map_join("", fn _ ->
      String.at(characters, :rand.uniform(String.length(characters)) - 1)
    end)
  end
end
