defmodule LoraWeb.Plugs.RequireAuth do
  @moduledoc """
  Plug to enforce authentication for certain routes.

  This plug ensures users are authenticated before accessing protected routes.
  If not authenticated, it stores the intended path and redirects to the Auth0 login page.
  """
  import Plug.Conn
  import Phoenix.Controller
  use LoraWeb, :verified_routes

  alias Lora.Accounts

  def init(opts), do: opts

  def call(conn, _opts) do
    player_id = get_session(conn, "player_id")

    if player_id && player_exists?(player_id) do
      # User is authenticated, touch their session to prevent expiry
      Accounts.touch_player(player_id)

      # Add current_player to the connection assigns
      {:ok, player} = Accounts.get_player(player_id)
      assign(conn, :current_player, player)
    else
      # Save the current path for redirecting after login
      target_path = conn.request_path
      encoded_target_path = URI.encode_www_form(target_path)

      conn
      |> put_session(:return_to, target_path)
      |> redirect(to: ~p"/auth/auth0?state=#{encoded_target_path}")
      |> halt()
    end
  end

  # Check if the player exists in the ETS store
  defp player_exists?(player_id) do
    case Accounts.get_player(player_id) do
      {:ok, _player} -> true
      {:error, _} -> false
    end
  end
end
