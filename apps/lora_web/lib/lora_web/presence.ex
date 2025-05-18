defmodule LoraWeb.Presence do
  use Phoenix.Presence,
    otp_app: :lora_web,
    pubsub_server: Lora.PubSub

  @doc """
  Returns a topic string for tracking game-specific presence.
  """
  def game_topic(game_id) when is_binary(game_id) do
    "presence::game::#{game_id}"
  end
end
