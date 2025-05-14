defmodule Lora.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Registry for game servers
      {Registry, keys: :unique, name: Lora.GameRegistry},

      # Start the game supervisor
      {Lora.GameSupervisor, []},

      # Start the PubSub system
      {Phoenix.PubSub, name: Lora.PubSub}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Lora.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
