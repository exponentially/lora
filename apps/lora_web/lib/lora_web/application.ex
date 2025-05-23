defmodule LoraWeb.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # Bypass phoenix_ecto dependency issues since we're not using a database
    Application.put_env(:phoenix, :json_library, Jason)

    children = [
      LoraWeb.Telemetry,
      # Start a worker by calling: LoraWeb.Worker.start_link(arg)
      # {LoraWeb.Worker, arg},
      # Start to serve requests, typically the last entry
      LoraWeb.Endpoint,
      LoraWeb.Presence
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: LoraWeb.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    LoraWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
