defmodule ExBanking.Balance do
  alias __MODULE__

  @enforce_keys [:currencies]
  defstruct [:currencies]

  def new(currencies) do
    {:ok, %Balance{currencies: Map.new(currencies, fn(currency) -> {currency, 0.0} end)}}
  end

  def get_amount(%Balance{currencies: currencies}, currency) do
    if amount = currencies[currency], do: {:ok, amount}, else: {:error, :wrong_arguments}
  end

  def update(%Balance{currencies: currencies} = balance, amount, currency) do
    with {:ok, current_amount} <- balance |> get_amount(currency),
      updated_amount <- Decimal.new(current_amount)
        |> Decimal.add(Decimal.new(amount))
        |> Decimal.round(2, :down)
        |> Decimal.to_float,
      true <- updated_amount >= 0
    do
      {:ok, %{balance | currencies: %{currencies | currency => updated_amount}}, updated_amount}
    else
      false -> {:error, :not_enough_money}
      error -> error
    end
  end
end
