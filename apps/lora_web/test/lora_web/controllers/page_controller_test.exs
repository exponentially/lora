defmodule LoraWeb.PageControllerTest do
  use LoraWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Lora Card Game"
    assert html_response(conn, 200) =~ "Create a New Game"
    assert html_response(conn, 200) =~ "Join an Existing Game"
  end
end
