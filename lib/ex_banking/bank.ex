defmodule ExBanking.Bank do
  alias ExBanking.{Bank, User}

  defstruct [:users, :currencies]

  def new(), do: {:ok, %Bank{users: %{}, currencies: MapSet.new()}}

  def create_user(%Bank{users: users, currencies: currencies} = bank, name) do
    with {:error, :user_does_not_exist} <- find_user(bank, name),
      {:ok, user} <- User.new(name, currencies)
    do
      {:ok, %{bank | users: Map.put(users, name, user)}, user}
    else
      {:ok, %User{}} -> {:error, :user_already_exists}
    end
  end

  def deposit(_bank, _name, amount, _currency) when amount < 0, do: {:error, :wrong_arguments}
  def deposit(bank, name, amount, currency) do
    with {:ok, %Bank{users: users} = bank} <- introduce_new_currency(bank, currency),
      {:ok, %User{} = user}  <- find_user(bank, name),
      {:ok, updated_user, balance_amount} <- User.update_balance(user, amount, currency)
    do
      {:ok, %{bank | users: %{users | name => updated_user}}, balance_amount}
    end
  end

  def withdraw(_bank, _name, amount, _currency) when amount < 0, do: {:error, :wrong_arguments}
  def withdraw(%Bank{users: users} = bank, name, amount, currency) do
    with {:ok, %User{} = user} <- find_user(bank, name),
      {:ok, updated_user, balance_amount} <- User.update_balance(user, -amount, currency)
    do
      {:ok, %{bank | users: %{users | name => updated_user}}, balance_amount}
    end
  end

  def get_balance(%Bank{} = bank, name, currency) do
    with {:ok, %User{} = user} <- find_user(bank, name),
      {:ok, amount} <- User.get_balance(user, currency)
    do
      {:ok, bank, amount}
    else
      error -> error
    end
  end

  def send(bank, sender_name, receiver_name, amount, currency) do
    case Bank.withdraw(bank, sender_name, amount, currency) do
      {:ok, %Bank{} = bank, sender_balance_amount} ->
        case Bank.deposit(bank, receiver_name, amount, currency) do
          {:ok, bank, receiver_balance_amount} ->
            {:ok, bank, sender_balance_amount, receiver_balance_amount}
          {:error, :user_does_not_exist} -> {:error, :receiver_does_not_exist}
          error -> error
        end
      {:error, :user_does_not_exist} -> {:error, :sender_does_not_exist}
      error -> error
    end
  end

  defp find_user(%Bank{users: users}, name) do
    if user = users[name], do: {:ok, user}, else: {:error, :user_does_not_exist}
  end

  defp introduce_new_currency(%Bank{users: users, currencies: currencies} = bank, currency) do
    case MapSet.member?(currencies, currency) do
      true -> {:ok, bank}
      false ->
        updated_users =
          users
          |> Map.new(
            fn({name, user}) ->
              {
                name,
                put_in(user, [Access.key(:balance), Access.key(:currencies), currency], 0)
              }
            end)
        {:ok, %{bank | users: updated_users, currencies: MapSet.put(currencies, currency)}}
    end
  end
end
