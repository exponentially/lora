defmodule Lora.ContractCallbacksTest do
  use ExUnit.Case, async: true

  alias Lora.Contract
  alias Lora.Game
  alias Lora.Contracts.Minimum
  alias Lora.Contracts.Maximum
  alias Lora.Contracts.Lora, as: LoraContract
  alias Lora.Contracts.Hearts
  alias Lora.Contracts.Queens
  alias Lora.Contracts.JackOfClubs
  alias Lora.Contracts.KingHeartsLastTrick

  # Define a test implementation to verify behavior
  defmodule TestContract do
    @behaviour Lora.Contract

    @impl true
    def name, do: "Test Contract"

    @impl true
    def description, do: "For testing purposes only"

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
    def pass(_game, _seat), do: {:error, "Passing not allowed"}
  end

  describe "Contract behaviour" do
    test "Contract module functions work with custom implementations" do
      assert Contract.name(TestContract) == "Test Contract"
      assert Contract.description(TestContract) == "For testing purposes only"
    end
  end

  describe "Contract modules API" do
    test "all/0 returns all contract modules" do
      contracts = Contract.all()
      assert is_list(contracts)
      assert length(contracts) == 7

      # Should return them in the predefined order
      assert contracts == [
        Minimum,
        Maximum,
        Queens,
        Hearts,
        JackOfClubs,
        KingHeartsLastTrick,
        LoraContract
      ]
    end

    test "at/1 returns correct contract module for each valid index" do
      assert Contract.at(0) == Minimum
      assert Contract.at(1) == Maximum
      assert Contract.at(2) == Queens
      assert Contract.at(3) == Hearts
      assert Contract.at(4) == JackOfClubs
      assert Contract.at(5) == KingHeartsLastTrick
      assert Contract.at(6) == LoraContract
    end

    test "at/1 raises error for invalid indices" do
      assert_raise FunctionClauseError, fn -> Contract.at(-1) end
      assert_raise FunctionClauseError, fn -> Contract.at(7) end
    end

    test "name/1 returns correct name for each contract" do
      assert Contract.name(Minimum) == "Minimum"
      assert Contract.name(Maximum) == "Maximum"
      assert Contract.name(Queens) == "Queens"
      assert Contract.name(Hearts) == "Hearts"
      assert Contract.name(JackOfClubs) == "Jack of Clubs"
      assert Contract.name(KingHeartsLastTrick) == "King of Hearts + Last Trick"
      assert Contract.name(LoraContract) == "Lora"
    end

    test "description/1 returns correct description for each contract" do
      assert Contract.description(Minimum) == "Plus one point per trick taken"
      assert Contract.description(Maximum) == "Minus one point per trick taken"
      assert Contract.description(Queens) == "Plus two points per queen taken"
      assert Contract.description(Hearts) ==
        "Plus one point per heart taken; minus eight if one player takes all hearts"
      assert Contract.description(JackOfClubs) ==
        "Plus eight points to the player who takes it"
      assert Contract.description(KingHeartsLastTrick) ==
        "Plus four points each for King of Hearts and Last Trick; plus eight if captured in the same trick"
      assert Contract.description(LoraContract) ==
        "Minus eight to the first player who empties hand; all others receive plus one point per remaining card"
    end
  end

  describe "contract validation" do
    test "every contract module implements required callbacks" do
      contracts = Contract.all()

      for contract <- contracts do
        # Verify each required callback is implemented
        assert function_exported?(contract, :name, 0)
        assert function_exported?(contract, :description, 0)
        assert function_exported?(contract, :is_legal_move?, 3)
        assert function_exported?(contract, :play_card, 4)
        assert function_exported?(contract, :calculate_scores, 4)
        assert function_exported?(contract, :handle_deal_over, 4)
        assert function_exported?(contract, :can_pass?, 2)
        assert function_exported?(contract, :pass, 2)

        # Call the functions to verify they return expected types
        name = contract.name()
        assert is_binary(name)

        desc = contract.description()
        assert is_binary(desc)

        # Create a basic game for testing other functions
        game = Game.new_game("test-game")
        can_pass = contract.can_pass?(game, 1)
        assert is_boolean(can_pass)
      end
    end
  end

  describe "working with specific contract implementations" do
    setup do
      game = Game.new_game("test-game")
      {:ok, game} = Game.add_player(game, "p1", "Player1")
      {:ok, game} = Game.add_player(game, "p2", "Player2")
      {:ok, game} = Game.add_player(game, "p3", "Player3")
      {:ok, game} = Game.add_player(game, "p4", "Player4")

      %{game: game}
    end

    test "contracts return expected results for basic functions", %{game: game} do
      contracts = Contract.all()

      for contract <- contracts do
        # Try to call can_pass? which should return a boolean for any contract
        result = contract.can_pass?(game, 1)
        assert is_boolean(result)

        # Try pass function which should return a tuple
        result = contract.pass(game, 1)
        assert is_tuple(result)
      end
    end

    test "Contract.at/1 works for all valid indices" do
      # Test all valid indices
      Enum.each(0..6, fn index ->
        contract = Contract.at(index)
        assert is_atom(contract)
      end)
    end
  end
end
