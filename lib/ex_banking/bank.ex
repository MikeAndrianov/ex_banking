defmodule ExBanking.Bank do
  alias ExBanking.{Bank, User}

  defstruct [:users, :currencies]

  def new(), do: {:ok, %Bank{users: %{}, currencies: MapSet.new()}}

  @doc """
  returns {:ok, %Bank{}, %User{}} or {:error, _}
  """
  def create_user(%Bank{users: users, currencies: currencies} = bank, name) do
    with true <- !find_user(bank, name),
      {:ok, user} <- User.new(name, currencies)
    do
      {:ok, %{bank | users: Map.put(users, name, user)}, user}
    else
      false -> {:error, :user_already_exists}
      # {:user_valid, false} -> {:error, dgettext("errors", "User not found")}
      # {:not_last_user, false} -> {:error, dgettext("errors", "Can not remove last user")}
    end
  end

  def deposit(bank, name, amount, currency) do
    with {:ok, %Bank{users: users} = bank} <- introduce_new_currency(bank, currency),
      %User{} = user <- find_user(bank, name),
      {:ok, updated_user, balance_amount} <- User.update_balance(user, amount, currency)
    do
      {:ok, %{bank | users: %{users | name => updated_user}}, balance_amount}
    else
      nil -> {:error, :user_does_not_exist}
      error -> error
    end
  end

  defp find_user(%Bank{users: users}, name), do: users[name]

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
