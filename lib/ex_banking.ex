defmodule ExBanking do
  @moduledoc """
  Documentation for ExBanking.
  """

  use GenServer
  alias ExBanking.Bank

  @type banking_error :: {:error,
    :wrong_arguments                |
    :user_already_exists            |
    :user_does_not_exist            |
    :not_enough_money               |
    :sender_does_not_exist          |
    :receiver_does_not_exist        |
    :too_many_requests_to_user      |
    :too_many_requests_to_sender    |
    :too_many_requests_to_receiver
  }

  def start_link(_args) do
    {:ok, _pid} = GenServer.start_link(__MODULE__, Bank.new(), name: __MODULE__)
  end

  @doc """
  Function creates new user in the system
  New user has zero balance of any currency
  """
  @spec create_user(user :: String.t) :: :ok | banking_error
  def create_user(user) when is_binary(user), do: GenServer.call(__MODULE__, {:create_user, user})

  @doc """
  Increases user's balance in given currency by amount value
  Returns new_balance of the user in given format
  """
  @spec deposit(user :: String.t, amount :: number, currency :: String.t) :: {:ok, new_balance :: number} | banking_error
  def deposit(user, amount, currency), do: GenServer.call(__MODULE__, {:deposit, user, amount, currency})

  @doc """
  Decreases user's balance in given currency by amount value
  Returns new_balance of the user in given format
  """
  @spec withdraw(user :: String.t, amount :: number, currency :: String.t) :: {:ok, new_balance :: number} | banking_error
  def withdraw(user, amount, currency), do: GenServer.call(__MODULE__, {:withdraw, user, amount, currency})

  @doc """
  Returns balance of the user in given format
  """
  @spec get_balance(user :: String.t, currency :: String.t) :: {:ok, balance :: number} | banking_error
  def get_balance(user, currency), do: GenServer.call(__MODULE__, {:get_balance, user, currency})

  @doc """
  Decreases from_user's balance in given currency by amount value
  Increases to_user's balance in given currency by amount value
  Returns balance of from_user and to_user in given format
  """
  @spec send(from_user :: String.t, to_user :: String.t, amount :: number, currency :: String.t) :: {:ok, from_user_balance :: number, to_user_balance :: number} | banking_error
  def send(from_user, to_user, amount, currency) do
    GenServer.call(__MODULE__, {:send, from_user, to_user, amount, currency})
  end

  def handle_call({:create_user, name}, _from, state_data) do
    case Bank.create_user(state_data, name) do
      {:ok, bank, _user} -> {:reply, :ok, bank}
      error -> {:reply, error, state_data}
    end
  end

  def handle_call({:deposit, name, amount, currency}, _from, state_data) do
    case Bank.deposit(state_data, name, amount, currency) do
      {:ok, bank, amount} -> {:reply, {:ok, amount}, bank}
      error -> {:reply, error, state_data}
    end
  end

  def handle_call({:withdraw, name, amount, currency}, _from, state_data) do
    case Bank.withdraw(state_data, name, amount, currency) do
      {:ok, bank, amount} -> {:reply, {:ok, amount}, bank}
      error -> {:reply, error, state_data}
    end
  end

  def handle_call({:get_balance, name, currency}, _from, state_data) do
    case Bank.get_balance(state_data, name, currency) do
      {:ok, bank, amount} -> {:reply, {:ok, amount}, bank}
      error -> {:reply, error, state_data}
    end
  end

  def handle_call({:send, sender, receiver, amount, currency}, _from, state_data) do
    case Bank.send(state_data, sender, receiver, amount, currency) do
      {:ok, bank, sender_amount, receiver_amount} -> {:reply, {:ok, sender_amount, receiver_amount}, bank}
      error -> {:reply, error, state_data}
    end
  end
end
