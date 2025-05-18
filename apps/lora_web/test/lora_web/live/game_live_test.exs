defmodule LoraWeb.GameLiveTest do
  use LoraWeb.LiveViewCase
  import Mock
  alias Lora.Accounts.Player

  test "displays game when authenticated", %{conn: conn} do
    game_id = "TESTID"

    # Mock the Lora.get_game_state function with a complete game state structure
    mock_game_state = %{
      id: game_id,
      phase: :lobby,
      players: [],
      dealer_seat: 1,
      contract_index: 0,
      hands: %{},
      trick: [],
      taken: %{},
      lora_layout: %{},
      scores: %{1 => 0, 2 => 0, 3 => 0, 4 => 0},
      current_player: nil,
      dealt_count: 0
    }

    # Setup a player in the system
    player = %Player{
      id: "test-id",
      sub: "test-id",
      name: "Test User",
      email: "test@example.com",
      inserted_at: DateTime.utc_now()
    }

    {:ok, _} = Lora.Accounts.store_player(player)

    # Mock Lora module functions
    with_mocks([
      {Lora, [],
       [
         get_game_state: fn _id -> {:ok, mock_game_state} end,
         add_player: fn _game_id, _player_id, _player_name -> {:ok, mock_game_state} end,
         player_reconnect: fn _game_id, _player_id, _pid -> :ok end,
         legal_moves: fn _game_id, _player_id -> {:ok, []} end,
         game_exists?: fn _id -> true end
       ]}
    ]) do
      # Initialize session with authenticated player
      conn =
        conn
        |> Plug.Test.init_test_session(%{"player_id" => "test-id"})

      # Connect to the game
      {:ok, _view, html} = live(conn, "/game/#{game_id}")

      # Verify game shows waiting state
      assert html =~ "Waiting for game to start"
      # Verify that we've successfully loaded the game with dealer info
      assert html =~ "Empty Seat 1"
      # Verify contract info is displayed
      assert html =~ "Minimum"
      assert html =~ "Plus one point per trick taken"
      # Verify game phase is displayed
      assert html =~ "Phase"
      assert html =~ "lobby"
    end
  end
end
