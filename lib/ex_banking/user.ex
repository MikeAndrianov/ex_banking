defmodule ExBanking.User do
  alias ExBanking.{User, Balance}

  defstruct [:name, :balance]

  def new(name, currencies) when is_binary(name) do
    case Balance.new(currencies) do
      {:ok, balance} ->
        {:ok, %User{name: name, balance: balance}}
      error -> error
    end
  end

  def update_balance(%User{balance: balance} = user, amount, currency) do
    # ...
    case Balance.update(balance, amount, currency) do
      {:ok, balance, amount} ->
        {:ok, %{user | balance: balance}, amount}
      error -> error
    end
  end
end
