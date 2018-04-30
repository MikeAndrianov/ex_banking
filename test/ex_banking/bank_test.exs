defmodule BankTest do
  use ExUnit.Case
  alias ExBanking.{Bank, User}

  describe "new/0" do
    test "creates new bank" do
      {:ok, %Bank{users: users, currencies: currencies}} = Bank.new

      assert users == %{}
      assert currencies == MapSet.new()
    end
  end

  describe "create_user/2" do
    test "adds user to bank" do
      {:ok, bank} = Bank.new

      assert {:ok, %Bank{users: %{"Joe" => %User{name: "Joe"} = user}}, user} =
        bank |> Bank.create_user("Joe")
    end

    test "refuses to add user with same name" do
      bank = %Bank{users: %{"Joe" => %User{name: "Joe"}}, currencies: MapSet.new()}

      assert {:error, :user_already_exists} = bank |> Bank.create_user("Joe")
    end

    test "sets zero balance of all existing currency" do
      bank = %Bank{users: %{}, currencies: MapSet.new(["USD", "EUR"])}
      {:ok, %Bank{}, %User{balance: balance}} = bank |> Bank.create_user("Joe")

      assert balance.currencies == %{"USD" => 0, "EUR" => 0}
    end
  end

  describe "deposit/4" do
    test "updates user balance" do
      {:ok, bank, _user} =
        %Bank{users: %{}, currencies: MapSet.new(["USD", "EUR"])}
        |> Bank.create_user("Joe")
      {:ok, %Bank{} = bank, 10} = Bank.deposit(bank, "Joe", 10, "USD")

      assert {:ok, %Bank{}, 20} = Bank.deposit(bank, "Joe", 10, "USD")
    end

    test "returns error if user was not found" do
      bank = %Bank{users: %{}, currencies: MapSet.new(["USD", "EUR"])}

      assert {:error, :user_does_not_exist} = Bank.deposit(bank, "Joe", 10, "USD")
    end

    test "returns error if user could not be updated" do
      {:ok, bank, _user} =
        %Bank{users: %{}, currencies: MapSet.new(["USD", "EUR"])}
        |> Bank.create_user("Joe")

      assert {:error, _} = Bank.deposit(bank, "Joe", -10, "USD")
    end

    test "updates all balances when new currency was introduced" do
      {:ok, bank, _user} =
        %Bank{users: %{}, currencies: MapSet.new(["USD"])}
        |> Bank.create_user("Joe")
      {:ok, bank, _user} = Bank.create_user(bank, "John")

      assert {
        :ok,
        %Bank{
          users: %{
            "Joe" => %User{name: "Joe"},
            "John" => %User{name: "John", balance: johns_balance}
          } = users
        },
        10
      } = Bank.deposit(bank, "Joe", 10, "EUR")
      assert johns_balance.currencies == %{"USD" => 0, "EUR" => 0}
    end
  end
end
