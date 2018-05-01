defmodule BalanceTest do
  use ExUnit.Case
  alias ExBanking.Balance

  describe "new/1" do
    test "creates balance with zero amount of all currencies" do
      {:ok, %Balance{currencies: currencies}} = Balance.new(MapSet.new(["USD", "EUR"]))

      assert currencies == %{"USD" => 0, "EUR" => 0}
    end
  end

  describe "update/3" do
    test "updates amount for currency" do
      balance = %Balance{currencies: %{"USD" => 10}}

      assert {:ok, %Balance{currencies: %{"USD" => 15}}, 15} =  Balance.update(balance, 5, "USD")
    end

    test "returns error when result amount less than 0" do
      balance = %Balance{currencies: %{"USD" => 10}}

      assert {:error, :not_enough_money} == Balance.update(balance, -15, "USD")
    end

    test "returns error when currency is absent" do
      balance = %Balance{currencies: %{"USD" => 10}}

      assert {:error, :wrong_arguments} == Balance.update(balance, -15, "EUR")
    end
  end
end
