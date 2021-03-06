defmodule BankTest do
  use ExUnit.Case
  alias ExBanking.{Bank, User}

  describe "new/0" do
    test "creates new bank" do
      %Bank{users: users, currencies: currencies} = Bank.new

      assert users == %{}
      assert currencies == MapSet.new()
    end
  end

  describe "create_user/2" do
    test "adds user to bank" do
      assert {:ok, %Bank{users: %{"Joe" => %User{name: "Joe"} = user}}, user} =
        Bank.new |> Bank.create_user("Joe")
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
      {:ok, %Bank{} = bank, 10.0} = Bank.deposit(bank, "Joe", 10, "USD")

      assert {:ok, %Bank{}, 20.0} = Bank.deposit(bank, "Joe", 10, "USD")
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
          }
        },
        10.0
      } = Bank.deposit(bank, "Joe", 10, "EUR")
      assert johns_balance.currencies == %{"USD" => 0, "EUR" => 0}
    end
  end

  describe "withdraw/4" do
    test "returns error if amount less than 0" do
      {:ok, bank, _user} =
        %Bank{users: %{}, currencies: MapSet.new(["USD", "EUR"])}
        |> Bank.create_user("Joe")

      assert Bank.withdraw(bank, "Joe", -10, "USD") == {:error, :wrong_arguments}
    end

    test "updates user balance" do
      {:ok, bank, _user} =
        %Bank{users: %{}, currencies: MapSet.new(["USD", "EUR"])}
        |> Bank.create_user("Joe")
      {:ok, bank, _amount} = Bank.deposit(bank, "Joe", 30, "USD")

      assert {:ok, %Bank{}, 20.0} = Bank.withdraw(bank, "Joe", 10, "USD")
    end

    test "returns error if user was not found" do
      bank = %Bank{users: %{}, currencies: MapSet.new(["USD", "EUR"])}

      assert {:error, :user_does_not_exist} = Bank.withdraw(bank, "Joe", 10, "USD")
    end
  end

  describe "get_balance/3" do
    test "returns amount for existing user" do
      {:ok, bank, _user} =
        %Bank{users: %{}, currencies: MapSet.new(["USD", "EUR"])}
        |> Bank.create_user("Joe")
      {:ok, bank, _amount} = Bank.deposit(bank, "Joe", 30, "USD")

      assert {:ok, %Bank{}, 30.0} = Bank.get_balance(bank, "Joe", "USD")
    end

    test "returns error if user was not found" do
      bank = %Bank{users: %{}}

      assert Bank.get_balance(bank, "Joe", "USD") == {:error, :user_does_not_exist}
    end
  end

  describe "send/5" do
    test "updates sender and receiver balances" do
      {:ok, bank, _user} =
        %Bank{users: %{}, currencies: MapSet.new(["USD", "EUR"])}
        |> Bank.create_user("Joe")
      {:ok, bank, _user} = bank |> Bank.create_user("James")
      {:ok, bank, _amount} = Bank.deposit(bank, "Joe", 30, "USD")

      assert {:ok, %Bank{}, 20.0, 10.0} = Bank.send(bank, "Joe", "James", 10, "USD")
    end

    test "returns error if user was not found" do
      {:ok, bank, _user} =
        %Bank{users: %{}, currencies: MapSet.new(["USD", "EUR"])}
        |> Bank.create_user("Joe")
      {:ok, bank, _amount} = Bank.deposit(bank, "Joe", 30, "USD")

      assert {:error, :receiver_does_not_exist} = Bank.send(bank, "Joe", "James", 10, "USD")
      assert {:error, :sender_does_not_exist} = Bank.send(bank, "James", "Joe", 10, "USD")
    end

    test "return error if currency does not exist" do
      {:ok, bank, _user} =
        %Bank{users: %{}, currencies: MapSet.new(["USD"])}
        |> Bank.create_user("Joe")
      {:ok, bank, _user} = bank |> Bank.create_user("James")
      {:ok, bank, _amount} = Bank.deposit(bank, "Joe", 30, "USD")

      assert {:error, :wrong_arguments} = Bank.send(bank, "Joe", "James", 10, "EUR")
    end
  end
end
