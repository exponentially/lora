defmodule LoraWeb.AuthTest do
  use LoraWeb.ConnCase

  import Mock

  alias Lora.Accounts
  alias Lora.Accounts.Player

  # Mock Auth0 response
  @auth0_response %Ueberauth.Auth{
    provider: :auth0,
    strategy: Ueberauth.Strategy.Helpers,
    uid: "auth0|12345678",
    info: %{
      name: "Test User",
      email: "test@example.com",
      nickname: "testuser"
    },
    credentials: %{
      token: "abc123",
      expires: true,
      expires_at: 1_622_222_222,
      refresh_token: "def456"
    },
    extra: %{}
  }

  # Setup Accounts ETS table for tests
  setup do
    # Check if the ETS table already exists
    case :ets.whereis(:players) do
      :undefined -> Accounts.init()
      # Table already exists
      _ -> :ok
    end

    :ok
  end

  describe "auth flow" do
    test "successful authentication redirects to the requested route", %{conn: conn} do
      # Set up a mock response for Ueberauth
      conn =
        conn
        |> Plug.Test.init_test_session(%{})
        |> assign(:ueberauth_auth, @auth0_response)
        |> get("/auth/auth0/callback", %{"state" => "/lobby#create"})

      # Check that we have a session with player_id and a redirect to the game URL
      assert redirected_to(conn) =~ "/game/"
      assert get_session(conn, "player_id") == "auth0|12345678"

      # Verify player was stored in ETS
      {:ok, player} = Accounts.get_player("auth0|12345678")
      assert player.name == "Test User"
      assert player.email == "test@example.com"
      assert player.sub == "auth0|12345678"
    end

    test "failed authentication redirects to lobby with error", %{conn: conn} do
      # Simulate failed Auth0 callback
      conn =
        conn
        |> Plug.Test.init_test_session(%{})
        |> assign(:ueberauth_failure, %{errors: [%{message: "Invalid credentials"}]})
        |> get("/auth/auth0/callback")

      # Check for redirect to lobby and error flash
      assert redirected_to(conn) == "/"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Authentication failed"
    end

    test "logout removes the player from ETS and session", %{conn: conn} do
      # Setup a player in the system
      player = %Player{
        id: "test-id",
        sub: "test-id",
        name: "Test User",
        email: "test@example.com",
        inserted_at: DateTime.utc_now()
      }

      {:ok, _} = Accounts.store_player(player)

      # Logout with a session containing the player_id
      conn =
        conn
        |> Plug.Test.init_test_session(%{"player_id" => "test-id"})
        |> delete("/auth/logout")

      # Verify the session is cleared and we're redirected to lobby
      assert redirected_to(conn) == "/"
      refute get_session(conn, "player_id")

      # Verify the player was removed from ETS
      assert {:error, _} = Accounts.get_player("test-id")
    end
  end

  describe "authentication guards" do
    test "RequireAuth redirects unauthenticated users to login", %{conn: conn} do
      conn =
        conn
        |> get("/game/123456")

      # The RequireAuth plug should redirect to Auth0 login
      assert redirected_to(conn) =~ "/auth/auth0"
      assert redirected_to(conn) =~ "%252Fgame%252F123456"
    end

    test "authenticated users can access protected routes", %{conn: conn} do
      # Setup a player in the system
      player = %Player{
        id: "test-id",
        sub: "test-id",
        name: "Test User",
        email: "test@example.com",
        inserted_at: DateTime.utc_now()
      }

      {:ok, _} = Accounts.store_player(player)

      # Mock the game exists function to allow the request
      with_mock Lora,
        get_game_state: fn _game_id -> {:ok, %{players: [], phase: :lobby}} end,
        player_reconnect: fn _game_id, _player_id, _pid -> :ok end,
        add_player: fn _game_id, _player_id, _player_name -> {:ok, %{players: []}} end,
        game_exists?: fn _game_id -> true end do
        conn =
          conn
          |> Plug.Test.init_test_session(%{"player_id" => "test-id"})
          |> get("/game/123456")

        # Should not redirect
        assert html_response(conn, 200)
      end
    end
  end
end
