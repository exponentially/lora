defmodule LoraWeb.LobbyLiveTest do
  use LoraWeb.LiveViewCase

  test "renders lobby form", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/")
    assert html =~ "Create Game"
    assert html =~ "Join Game"
  end

  test "create game - shows error with empty player name", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    # Submit form with empty player name
    html =
      view
      |> element("#create-game-form")
      |> render_submit(%{create_player: %{name: ""}})

    # Verify error message is shown
    assert html =~ "Please enter a valid name"
  end

  test "join game - shows error with empty player name", %{conn: conn} do
    game_id = "TESTID"

    {:ok, view, _html} = live(conn, "/")

    # Submit form with empty player name
    html =
      view
      |> element("#join-game-form")
      |> render_submit(%{join_player: %{name: "", game_code: game_id}})

    # Verify error message is shown
    assert html =~ "Please enter a valid name"
  end

  test "join game - shows error with empty game ID", %{conn: conn} do
    player_name = "TestPlayer"

    {:ok, view, _html} = live(conn, "/")

    # Submit form with empty game ID
    html =
      view
      |> element("#join-game-form")
      |> render_submit(%{join_player: %{name: player_name, game_code: ""}})

    # Verify error message is shown
    assert html =~ "Please enter a valid game code"
  end
end
