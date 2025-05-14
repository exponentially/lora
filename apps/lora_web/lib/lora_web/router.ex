defmodule LoraWeb.Router do
  use LoraWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {LoraWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :ensure_player_id_generated
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", LoraWeb do
    pipe_through :browser

    # Replace the default route with our lobby
    live "/", LobbyLive, :index

    # Game routes
    live "/game/:id", GameLive, :show
  end

  # Other scopes may use custom stacks.
  # scope "/api", LoraWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:lora_web, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: LoraWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  # Ensure a player ID is generated and stored in the session
  defp ensure_player_id_generated(conn, _opts) do
    if get_session(conn, "player_id") do
      conn
    else
      player_id = generate_player_id()
      put_session(conn, "player_id", player_id)
    end
  end

  # Generate a random player ID - used in both production and tests
  defp generate_player_id do
    :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
  end
end
