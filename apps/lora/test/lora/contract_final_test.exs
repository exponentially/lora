defmodule Lora.ContractFinalTest do
  use ExUnit.Case, async: true

  alias Lora.Contract

  describe "Contract module direct invocations" do
    test "all/0 returns the correct list of modules" do
      contracts = Contract.all()
      assert is_list(contracts)
      assert length(contracts) == 7
    end

    test "at/1 function with every valid index" do
      assert Contract.at(0) == Lora.Contracts.Minimum
      assert Contract.at(1) == Lora.Contracts.Maximum
      assert Contract.at(2) == Lora.Contracts.Queens
      assert Contract.at(3) == Lora.Contracts.Hearts
      assert Contract.at(4) == Lora.Contracts.JackOfClubs
      assert Contract.at(5) == Lora.Contracts.KingHeartsLastTrick
      assert Contract.at(6) == Lora.Contracts.Lora
    end

    test "at/1 function raises FunctionClauseError for out-of-bounds indices" do
      # Test invalid indices
      assert_raise FunctionClauseError, fn -> Contract.at(-1) end
      assert_raise FunctionClauseError, fn -> Contract.at(7) end
      assert_raise FunctionClauseError, fn -> Contract.at(100) end
    end

    test "name/1 directly calls contract_module.name()" do
      for contract_module <- Contract.all() do
        expected_name = contract_module.name()
        actual_name = Contract.name(contract_module)
        assert actual_name == expected_name
      end
    end

    test "description/1 directly calls contract_module.description()" do
      for contract_module <- Contract.all() do
        expected_description = contract_module.description()
        actual_description = Contract.description(contract_module)
        assert actual_description == expected_description
      end
    end

    test "Contract module helper functions return correct values" do
      assert Contract.name(Lora.Contracts.Minimum) == "Minimum"
      assert Contract.name(Lora.Contracts.Maximum) == "Maximum"

      assert Contract.description(Lora.Contracts.Hearts) ==
        "Plus one point per heart taken; minus eight if one player takes all hearts"
      assert Contract.description(Lora.Contracts.JackOfClubs) ==
        "Plus eight points to the player who takes it"
    end

    test "Contract behavior with explicit module calls" do
      # Test that we can directly call Contract.name on a module
      mod = Lora.Contracts.Minimum
      assert Contract.name(mod) == "Minimum"
    end
  end

  # Test with a mock implementation
  defmodule MockContract do
    @behaviour Lora.Contract

    @impl true
    def name, do: "Mock Contract"

    @impl true
    def description, do: "Mock description"

    # Implement the required callbacks with minimal functionality
    @impl true
    def is_legal_move?(_game, _seat, _card), do: true

    @impl true
    def play_card(game, _seat, _card, _hands), do: {:ok, game}

    @impl true
    def calculate_scores(_game, _taken, _hands, _dealer_seat), do: %{}

    @impl true
    def handle_deal_over(game, _taken, _hands, _dealer_seat), do: game

    @impl true
    def can_pass?(_game, _seat), do: false

    @impl true
    def pass(_game, _seat), do: {:error, "Cannot pass"}
  end

  test "Contract.name with mock implementation" do
    assert Contract.name(MockContract) == "Mock Contract"
  end

  test "Contract.description with mock implementation" do
    assert Contract.description(MockContract) == "Mock description"
  end
end
