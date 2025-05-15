defmodule LoraWeb.Test do
  @moduledoc """
  Test helpers for setting up test sessions and other test utilities.
  """

  @doc """
  Sets up a test session with player information.
  """
  def setup_test_session(_tags) do
    # Default player ID for tests
    player_id = "test_player_#{:rand.uniform(1000)}"

    # Return the session data
    %{
      player_id: player_id,
      session: %{"player_id" => player_id, "player_name" => "Test Player"}
    }
  end
end
