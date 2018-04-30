defmodule ExBanking.Bank do
  alias ExBanking.{Bank, User}

  defstruct [:users, :currencies]

  def new(), do: {:ok, %Bank{users: [], currencies: MapSet.new()}}

  @doc """
  returns {:ok, %Bank{}, %User{}} or {:error, _}
  """
  def create_user(%Bank{users: users, currencies: currencies} = bank, name) do
    with true <- !find_user(bank, name),
      {:ok, user} <- User.new(name, currencies)
    do
      {:ok, %{bank | users: [user | users]}, user}
    else
      false -> {:error, :user_already_exists}
      # {:user_valid, false} -> {:error, dgettext("errors", "User not found")}
      # {:not_last_user, false} -> {:error, dgettext("errors", "Can not remove last user")}
    end
  end

  def deposit(%Bank{users: users} = bank, name, amount, currency) do
    with {:ok, bank} <- introduce_new_currency(bank, currency),
      %User{} = user <- find_user(bank, name),
      {:ok, updated_user, balance_amount} <- User.update_balance(user, amount, currency)
    do
      {:ok, %{bank | users: [updated_user | users -- [user]]}, balance_amount}
    else
      nil -> {:error, :user_does_not_exist}
      error -> error
    end
  end

  defp find_user(%Bank{users: users}, name), do: Enum.find(users, fn(user) -> user.name == name end)

  defp introduce_new_currency(%Bank{users: users, currencies: currencies} = bank, currency) do
    case MapSet.member?(currencies, currency) do
      true -> {:ok, bank}
      false ->
        updated_users =
          users
          |> Enum.map(&(put_in(&1, [Access.key(:balance), Access.key(:currencies), currency], 0)))
        {:ok, %{bank | users: updated_users, currencies: MapSet.put(currencies, currency)}}
    end
  end
end
