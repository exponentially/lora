defmodule Lora.Accounts do
  @moduledoc """
  The Accounts context responsible for player authentication and management.
  """

  alias Lora.Accounts.Player

  # Use the ETS adapter as the default implementation
  @adapter Lora.Accounts.ETSAdapter

  @doc """
  Initialize the accounts system.
  """
  def init do
    @adapter.init()
  end

  @doc """
  Get a player by ID.
  """
  def get_player(player_id) do
    @adapter.get_player(player_id)
  end

  @doc """
  Store a player.
  """
  def store_player(%Player{} = player) do
    @adapter.store_player(player)
  end

  @doc """
  Delete a player.
  """
  def delete_player(player_id) do
    @adapter.delete_player(player_id)
  end

  @doc """
  Update the timestamp for a player to prevent session expiry.
  """
  def touch_player(player_id) do
    @adapter.touch_player(player_id)
  end

  @doc """
  Create a player from Auth0 authentication information.
  """
  def create_player_from_auth(%Ueberauth.Auth{} = auth) do
    player = Player.from_auth(auth)
    store_player(player)
  end
end
