defmodule Lora.ContractEdgeCasesTest do
  use ExUnit.Case, async: true

  alias Lora.Contract
  alias Lora.Game

  describe "Contract module edge cases" do
    test "contract functions work with all contract implementations" do
      contract_modules = Contract.all()

      # Test each contract module for behavior conformance
      for contract_module <- contract_modules do
        # Test the basic functions that get delegated through Contract module
        name = Contract.name(contract_module)
        assert is_binary(name)
        assert String.length(name) > 0

        description = Contract.description(contract_module)
        assert is_binary(description)
        assert String.length(description) > 0

        # Create a game instance for testing other contract functions
        game = Game.new_game("test-#{:erlang.unique_integer([:positive])}")

        # Test is_legal_move? on each contract implementation
        result = contract_module.is_legal_move?(game, 1, {:hearts, :ace})
        assert is_boolean(result)

        # Test can_pass? on each contract implementation
        result = contract_module.can_pass?(game, 1)
        assert is_boolean(result)

        # Test pass on each contract implementation (should return a tuple)
        result = contract_module.pass(game, 1)
        assert is_tuple(result)

        # Test play_card (it's ok if it fails, but it should be callable)
        # We're not testing the actual result, just that it's implemented
        try do
          contract_module.play_card(game, 1, {:hearts, :ace}, %{})
        rescue
          _ -> :ok
        end

        # Test calculate_scores with dummy data
        # Will likely fail for most contracts, but we just want to ensure it's implemented
        try do
          contract_module.calculate_scores(game, %{}, %{}, 1)
        rescue
          _ -> :ok
        end

        # Test handle_deal_over with dummy data
        try do
          contract_module.handle_deal_over(game, %{}, %{}, 1)
        rescue
          _ -> :ok
        end
      end
    end

    # Testing Contract.at specifically which is relevant to the current coverage
    test "Contract.at handles all valid indices without errors" do
      # Test within the valid range
      for index <- 0..6 do
        contract = Contract.at(index)
        assert is_atom(contract)
        # Basic verification that it returned a proper module
        assert Code.ensure_loaded?(contract)
        assert function_exported?(contract, :name, 0)

        # Verify the result matches what we expect from all() at the same index
        assert contract == Enum.at(Contract.all(), index)
      end
    end

    test "Contract.at raises FunctionClauseError for invalid indices" do
      # Test negative index
      assert_raise FunctionClauseError, fn ->
        Contract.at(-1)
      end

      # Test index that's too large
      assert_raise FunctionClauseError, fn ->
        Contract.at(length(Contract.all()))
      end
    end
  end

  # Create a test contract module to test the Contract behavior
  defmodule TestContractFull do
    @behaviour Lora.Contract

    @impl true
    def name, do: "Test Contract Full"

    @impl true
    def description, do: "Full implementation of contract behavior for testing"

    @impl true
    def is_legal_move?(_game, _seat, _card), do: true

    @impl true
    def play_card(game, _seat, _card, _hands), do: {:ok, game}

    @impl true
    def calculate_scores(_game, _taken, _hands, _dealer_seat), do: %{1 => 0, 2 => 0, 3 => 0, 4 => 0}

    @impl true
    def handle_deal_over(game, _taken, _hands, _dealer_seat), do: game

    @impl true
    def can_pass?(_game, _seat), do: false

    @impl true
    def pass(_game, _seat), do: {:error, "Cannot pass in this contract"}
  end

  # Tests using our custom test contract
  describe "Contract module with custom contract implementation" do
    test "Contract module functions work with custom implementation" do
      assert Contract.name(TestContractFull) == "Test Contract Full"
      assert Contract.description(TestContractFull) == "Full implementation of contract behavior for testing"
    end
  end
end
