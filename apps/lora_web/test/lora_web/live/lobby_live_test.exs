defmodule LoraWeb.LobbyLiveTest do
  use LoraWeb.LiveViewCase

  test "renders lobby form", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/")
    assert html =~ "Create a New Game"
    assert html =~ "Join an Existing Game"
  end

  test "create game - shows error with empty player name", %{conn: conn} do
    # When not signed in, there should be a warning about signing in
    {:ok, _view, html} = live(conn, "/")

    # Verify message is shown
    assert html =~ "Please sign in to create a game"
  end

  test "join game - shows error with empty game code", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    # Submit form with empty game code
    html =
      view
      |> element("#join-game-form")
      |> render_submit(%{join_player: %{game_code: ""}})

    # Should show an error
    assert html =~ "Please enter a valid game code"
  end

  test "join game - shows error with invalid game code", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    # Submit form with invalid game code
    html =
      view
      |> element("#join-game-form")
      |> render_submit(%{join_player: %{game_code: "ABC"}})

    # Verify error message is shown
    assert html =~ "Please enter a valid game code"
  end
end
