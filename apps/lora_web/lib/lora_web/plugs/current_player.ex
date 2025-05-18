defmodule LoraWeb.Plugs.CurrentPlayer do
  @moduledoc """
  Plug to assign the current player to the connection if authenticated.

  This plug doesn't enforce authentication but makes the player info available
  if the user is authenticated.
  """
  import Plug.Conn

  alias Lora.Accounts

  def init(opts), do: opts

  def call(conn, _opts) do
    player_id = get_session(conn, "player_id")

    if player_id do
      case Accounts.get_player(player_id) do
        {:ok, player} ->
          # User is authenticated, touch their session to prevent expiry
          Accounts.touch_player(player_id)
          assign(conn, :current_player, player)

        {:error, _} ->
          # Player not found in ETS, remove from session
          conn
          |> delete_session("player_id")
          |> assign(:current_player, nil)
      end
    else
      assign(conn, :current_player, nil)
    end
  end
end
