defmodule UserTest do
  use ExUnit.Case
  alias ExBanking.{User, Balance}

  describe "new/2" do
    test "creates user with balance" do
      {:ok, %User{name: name, balance: %Balance{}}} = User.new("Joe", ["USD", "EUR"])

      assert name == "Joe"
    end
  end

  describe "update_balance/3" do
    # deposit could be more than 0!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

    test "updates amount for currency" do
      user = %User{balance: %Balance{currencies: %{"USD" => 10}}}

      assert {:ok, %User{balance: balance}, 15} =  User.update_balance(user, 5, "USD")
      assert balance.currencies["USD"] == 15
    end

    test "returns error when balance was not updated" do
      user = %User{balance: %Balance{currencies: %{"USD" => 10}}}

      assert {:error, :wrong_arguments} == User.update_balance(user, -15, "USD")
    end
  end
end
