defmodule Lora.Accounts.AccountsBehaviour do
  @moduledoc """
  Behaviour for the Accounts context to allow swapping implementations.
  """
  alias Lora.Accounts.Player

  @callback get_player(player_id :: String.t()) :: {:ok, Player.t()} | {:error, String.t()}
  @callback store_player(player :: Player.t()) :: {:ok, Player.t()} | {:error, String.t()}
  @callback delete_player(player_id :: String.t()) :: :ok | {:error, String.t()}
  @callback touch_player(player_id :: String.t()) :: :ok | {:error, String.t()}
end
