defmodule Lora.Repo do
  use Ecto.Repo,
    otp_app: :lora,
    adapter: Ecto.Adapters.Postgres
end
