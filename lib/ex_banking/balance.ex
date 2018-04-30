defmodule ExBanking.Balance do
  alias __MODULE__

  @enforce_keys [:currencies]
  defstruct [:currencies]

  def new(currencies) do
    {:ok, %Balance{currencies: Map.new(currencies, fn(currency) -> {currency, 0} end)}}
  end

  @doc """
  returns {:ok, %Balance{}, amount} or {:error, :wrong_arguments}
  """
  def update(%Balance{currencies: currencies} = balance, amount, currency) do
    case currencies[currency] + amount do
      updated_amount when updated_amount >= 0 ->
        {:ok, %{balance | currencies: %{currencies | currency => updated_amount}}, updated_amount}
      _ ->
        {:error, :wrong_arguments}
    end
  end
end
