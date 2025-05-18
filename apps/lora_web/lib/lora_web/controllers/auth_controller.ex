defmodule LoraWeb.AuthController do
  use LoraWeb, :controller
  alias Lora.Accounts
  require Logger

  plug Ueberauth

  @doc """
  Callback handler for Auth0 authentication.
  """
  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, params) do
    # Create and store player in ETS
    Logger.debug("AUTH CALLBACK - auth: #{inspect(auth)}")

    {:ok, player} = Accounts.create_player_from_auth(auth)
    Logger.debug("AUTH CALLBACK - player created: #{inspect(player)}")

    # Store player ID in session
    conn = put_session(conn, "player_id", player.sub)
    Logger.debug("AUTH CALLBACK - set player_id in session: #{player.sub}")

    # Handle the redirect based on the state parameter
    state = params["state"]

    cond do
      state == "/lobby#create" ->
        # Create a new game and redirect to it
        case Lora.create_game(player.sub, player.name) do
          {:ok, game_id} ->
            redirect(conn, to: ~p"/game/#{game_id}")

          {:error, _reason} ->
            conn
            |> put_flash(:error, "Failed to create a new game")
            |> redirect(to: ~p"/")
        end

      String.starts_with?(state, "/game/") ->
        # Try to join the game specified in the state
        game_id = String.replace_prefix(state, "/game/", "")

        case Lora.join_game(game_id, player.sub, player.name) do
          {:ok, _game} ->
            redirect(conn, to: state)

          {:error, reason} ->
            conn
            |> put_flash(:error, reason)
            |> redirect(to: ~p"/")
        end

      true ->
        # Default: redirect to the saved return path or root
        redirect_path = get_session(conn, :return_to) || "/"

        conn
        |> delete_session(:return_to)
        |> redirect(to: redirect_path)
    end
  end

  def callback(%{assigns: %{ueberauth_failure: _failure}} = conn, _params) do
    conn
    |> put_flash(:error, "Authentication failed")
    |> redirect(to: ~p"/")
  end

  @doc """
  Logout the current user.
  """
  def delete(conn, _params) do
    # Get the player ID from the session
    player_id = get_session(conn, "player_id")

    # Delete the player from ETS if they exist
    if player_id do
      Accounts.delete_player(player_id)
    end

    # Clear the session
    conn
    |> clear_session()
    |> redirect(to: ~p"/")
  end
end
