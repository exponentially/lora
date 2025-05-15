defmodule Lora.ContractTest do
  use ExUnit.Case, async: true

  alias Lora.Contract

  describe "all/0" do
    test "returns the list of contract modules in the correct order" do
      contracts = Contract.all()
      assert length(contracts) == 7
      assert Enum.at(contracts, 0) == Lora.Contracts.Minimum
      assert Enum.at(contracts, 1) == Lora.Contracts.Maximum
      assert Enum.at(contracts, 2) == Lora.Contracts.Queens
      assert Enum.at(contracts, 3) == Lora.Contracts.Hearts
      assert Enum.at(contracts, 4) == Lora.Contracts.JackOfClubs
      assert Enum.at(contracts, 5) == Lora.Contracts.KingHeartsLastTrick
      assert Enum.at(contracts, 6) == Lora.Contracts.Lora
    end
  end

  describe "at/1" do
    test "returns the correct contract module for a given index" do
      assert Contract.at(0) == Lora.Contracts.Minimum
      assert Contract.at(1) == Lora.Contracts.Maximum
      assert Contract.at(2) == Lora.Contracts.Queens
      assert Contract.at(3) == Lora.Contracts.Hearts
      assert Contract.at(4) == Lora.Contracts.JackOfClubs
      assert Contract.at(5) == Lora.Contracts.KingHeartsLastTrick
      assert Contract.at(6) == Lora.Contracts.Lora
    end
  end

  describe "name/1" do
    test "returns the contract name from the module's callback" do
      assert Contract.name(Lora.Contracts.Minimum) == "Minimum"
      assert Contract.name(Lora.Contracts.Maximum) == "Maximum"
      assert Contract.name(Lora.Contracts.Queens) == "Queens"
      assert Contract.name(Lora.Contracts.Hearts) == "Hearts"
      assert Contract.name(Lora.Contracts.JackOfClubs) == "Jack of Clubs"
      assert Contract.name(Lora.Contracts.KingHeartsLastTrick) == "King of Hearts + Last Trick"
      assert Contract.name(Lora.Contracts.Lora) == "Lora"
    end
  end

  describe "description/1" do
    test "returns the contract description from the module's callback" do
      assert Contract.description(Lora.Contracts.Minimum) == "Plus one point per trick taken"
      assert Contract.description(Lora.Contracts.Maximum) == "Minus one point per trick taken"
      assert Contract.description(Lora.Contracts.Queens) == "Plus two points per queen taken"

      assert Contract.description(Lora.Contracts.Hearts) ==
               "Plus one point per heart taken; minus eight if one player takes all hearts"

      assert Contract.description(Lora.Contracts.JackOfClubs) ==
               "Plus eight points to the player who takes it"

      assert Contract.description(Lora.Contracts.KingHeartsLastTrick) ==
               "Plus four points each for King of Hearts and Last Trick; plus eight if captured in the same trick"

      assert Contract.description(Lora.Contracts.Lora) ==
               "Minus eight to the first player who empties hand; all others receive plus one point per remaining card"
    end
  end
end
