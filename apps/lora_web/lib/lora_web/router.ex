defmodule LoraWeb.Router do
  use LoraWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {LoraWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug LoraWeb.Plugs.CurrentPlayer
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Add authentication required pipeline
  pipeline :auth_required do
    plug LoraWeb.Plugs.RequireAuth
  end

  # Unauthenticated routes
  scope "/", LoraWeb do
    pipe_through :browser

    # Replace the default route with our lobby
    live_session :default, on_mount: {LoraWeb.LiveAuth, :default} do
      live "/", LobbyLive, :index
    end
  end

  # Authentication routes
  scope "/auth", LoraWeb do
    pipe_through :browser

    # Auth0 routes handled by Ueberauth
    get "/:provider", AuthController, :request
    get "/:provider/callback", AuthController, :callback
    delete "/logout", AuthController, :delete
  end

  # Routes that require authentication
  scope "/", LoraWeb do
    pipe_through [:browser, :auth_required]

    # Game routes
    live_session :authenticated, on_mount: {LoraWeb.LiveAuth, :default} do
      live "/game/:id", GameLive, :show
    end
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

end
