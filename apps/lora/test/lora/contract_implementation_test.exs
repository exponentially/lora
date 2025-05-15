defmodule Lora.ContractImplementationTest do
  use ExUnit.Case, async: true

  alias Lora.Contract

  # Define a mock implementation of the Contract behavior for testing
  defmodule MockContract do
    @behaviour Lora.Contract

    @impl true
    def name, do: "Mock Contract"

    @impl true
    def description, do: "This is a mock contract for testing"

    @impl true
    def is_legal_move?(_game, _seat, _card), do: true

    @impl true
    def play_card(game, _seat, _card, _hands), do: {:ok, game}

    @impl true
    def calculate_scores(_game, _taken, _hands, _dealer_seat), do: %{1 => 5, 2 => 0, 3 => 0, 4 => 0}

    @impl true
    def handle_deal_over(game, _taken, _hands, _dealer_seat), do: game

    @impl true
    def can_pass?(_game, _seat), do: false

    @impl true
    def pass(_game, _seat), do: {:error, "Not allowed"}
  end

  describe "contract behavior implementation" do
    test "Contract module provides access to implementation functions" do
      # Test dynamic dispatching via the Contract module
      assert Contract.name(MockContract) == "Mock Contract"
      assert Contract.description(MockContract) == "This is a mock contract for testing"
    end

    test "all/0 returns all contract modules" do
      contracts = Contract.all()
      assert is_list(contracts)
      assert length(contracts) == 7

      # All items should be modules
      Enum.each(contracts, fn contract ->
        assert is_atom(contract)
        # Ensure the module is loaded
        assert Code.ensure_loaded?(contract)
        # Verify they implement the ContractBehaviour
        assert function_exported?(contract, :name, 0)
        assert function_exported?(contract, :description, 0)
        assert function_exported?(contract, :is_legal_move?, 3)
        assert function_exported?(contract, :play_card, 4)
        assert function_exported?(contract, :calculate_scores, 4)
        assert function_exported?(contract, :handle_deal_over, 4)
        assert function_exported?(contract, :can_pass?, 2)
        assert function_exported?(contract, :pass, 2)
      end)
    end

    test "at/1 with boundary values" do
      # Valid indices
      assert is_atom(Contract.at(0))
      assert is_atom(Contract.at(6))

      # First should be Minimum
      assert Contract.at(0) == Lora.Contracts.Minimum
      # Last should be Lora
      assert Contract.at(6) == Lora.Contracts.Lora

      # Invalid indices should raise an error
      assert_raise FunctionClauseError, fn -> Contract.at(-1) end
      assert_raise FunctionClauseError, fn -> Contract.at(7) end
      assert_raise FunctionClauseError, fn -> Contract.at(100) end
    end
  end
end
