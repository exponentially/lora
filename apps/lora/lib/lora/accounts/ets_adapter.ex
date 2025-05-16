defmodule Lora.Accounts.ETSAdapter do
  @moduledoc """
  ETS-based implementation of the Accounts context.
  """
  @behaviour Lora.Accounts.AccountsBehaviour

  alias Lora.Accounts.Player
  require Logger

  @table_name :players
  @expiry_time_seconds 30 * 60 # 30 minutes

  @doc """
  Initialize the ETS table for players.
  """
  def init do
    :ets.new(@table_name, [:set, :public, :named_table])
    schedule_cleanup()
    :ok
  end

  @impl true
  def get_player(player_id) when is_binary(player_id) do
    case :ets.lookup(@table_name, player_id) do
      [{^player_id, player}] ->
        {:ok, player}

      [] ->
        {:error, "Player not found"}
    end
  end

  @impl true
  def store_player(%Player{} = player) do
    true = :ets.insert(@table_name, {player.sub, player})
    {:ok, player}
  end

  @impl true
  def delete_player(player_id) when is_binary(player_id) do
    true = :ets.delete(@table_name, player_id)
    :ok
  end

  @impl true
  def touch_player(player_id) when is_binary(player_id) do
    case get_player(player_id) do
      {:ok, player} ->
        player = %Player{player | inserted_at: DateTime.utc_now()}
        store_player(player)
        :ok

      error ->
        error
    end
  end  # Schedule a periodic cleanup of expired sessions
  defp schedule_cleanup do
    # Since we're not a GenServer, we'll use a Task instead
    Task.start(fn ->
      Process.sleep(60_000) # Wait 1 minute
      cleanup_expired_players()
      schedule_cleanup()
    end)
  end

  # Clean up expired player entries
  defp cleanup_expired_players do
    now = DateTime.utc_now()
    expiry_threshold = DateTime.add(now, -@expiry_time_seconds, :second)

    # Perform the cleanup by iterating through the table
    :ets.foldl(
      fn {id, player}, acc ->
        if DateTime.compare(player.inserted_at, expiry_threshold) == :lt do
          Logger.info("Removing expired player session for #{player.name}")
          :ets.delete(@table_name, id)
        end
        acc
      end,
      nil,
      @table_name
    )
  end
end
