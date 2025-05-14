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

  @doc """
  Mock implementations for Lora API functions used in tests.
  These functions will be used with the Mock library.
  """
  def mock_lora_api do
    [
      generate_player_id: fn -> "test-player-id" end,
      create_game: fn _player_name -> {:ok, "TESTID"} end,
      join_game: fn game_id, player_name, player_id ->
        case game_id do
          "INVALID" ->
            {:error, :not_found}

          _ ->
            {:ok,
             %{
               id: game_id,
               players: [%{id: player_id, name: player_name, seat: 1}],
               phase: :lobby
             }}
        end
      end,
      get_game_state: fn game_id ->
        case game_id do
          "NOTFOUND" ->
            {:error, :not_found}

          _ ->
            {:ok,
             %{
               id: game_id,
               phase: :lobby,
               taken: %{},
               players: [%{id: "test-player-id", name: "TestPlayer", seat: 1}],
               dealer_seat: 1,
               contract_index: 0,
               hands: %{},
               trick: [],
               lora_layout: %{},
               scores: %{1 => 0, 2 => 0, 3 => 0, 4 => 0},
               current_player: nil,
               dealt_count: 0
             }}
        end
      end,
      add_player: fn game_id, player_id, player_name ->
        {:ok,
         %{
           id: game_id,
           phase: :lobby,
           taken: %{},
           players: [%{id: player_id, name: player_name, seat: 1}],
           dealer_seat: 1,
           contract_index: 0,
           hands: %{},
           trick: [],
           lora_layout: %{},
           scores: %{1 => 0, 2 => 0, 3 => 0, 4 => 0},
           current_player: nil,
           dealt_count: 0
         }}
      end,
      player_reconnect: fn _game_id, _player_id, _pid -> :ok end,
      legal_moves: fn _game_id, _player_id -> {:ok, []} end
    ]
  end
end
