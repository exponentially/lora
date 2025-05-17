defmodule LoraWeb.LiveAuth do
  @moduledoc """
  LiveView hook to handle authentication for LiveViews.
  """
  import Phoenix.Component

  alias Lora.Accounts
  require Logger

  def on_mount(:default, _params, session, socket) do
    player_id = Map.get(session, "player_id")
    Logger.debug("player_id from session: #{inspect(player_id)}")

    if player_id do
      case Accounts.get_player(player_id) do
        {:ok, player} ->
          Logger.debug("player found: #{inspect(player)}")
          # Touch the player session to extend it
          Accounts.touch_player(player_id)

          # Debug - inspect socket before and after assign
          socket = assign(socket, :current_player, player)

          {:cont, socket}

        {:error, reason} ->
          Logger.debug("Player not found: #{reason}")
          {:cont, assign(socket, :current_player, nil)}
      end
    else
      Logger.debug("no player_id in session")
      {:cont, assign(socket, :current_player, nil)}
    end
  end
end
