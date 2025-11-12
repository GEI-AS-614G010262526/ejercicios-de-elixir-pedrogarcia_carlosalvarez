defmodule Server do
  @moduledoc """
  Servidor del micro bank implementado con GenServer.
  API pública:
    - start_link(initial_accounts \\ []) :: {:ok, pid()}
      initial_accounts: lista de tuplas [{account, balance}, ...] opcional.

    - stop() :: :ok

    - deposit(account, amount) :: {:ok, new_balance}

    - withdraw(account, amount) :: {:ok, new_balance} | {:error, :insufficient_funds}

    - ask(account) :: {:ok, balance} | {:error, :not_found}
  """

  use GenServer


  @spec start_link(list({atom(), number()})) :: {:ok, pid()}
  def start_link(initial_accounts \\ []) when is_list(initial_accounts) do
    GenServer.start_link(__MODULE__, initial_accounts, name: __MODULE__)
  end

  @spec stop() :: :ok
  def stop do
    GenServer.stop(__MODULE__, :normal)
  end

  @spec deposit(atom(), number()) :: {:ok, number()} | {:error, :not_found}
  def deposit(who, amount) do
    GenServer.call(__MODULE__, {:deposit, who, amount})
  end

  @spec withdraw(atom(), number()) :: {:ok, number()} | {:error, :not_found} | {:error, :insufficient_funds}
  def withdraw(who, amount) do
    GenServer.call(__MODULE__, {:withdraw, who, amount})
  end

  @spec ask(atom()) :: {:ok, number()} | {:error, :not_found}
  def ask(who) when is_atom(who) do
    GenServer.call(__MODULE__, {:ask, who})
  end

  ## Server callbacks

  @impl true
  def init(initial_accounts) do
    # inicializamos el estado como un mapa account -> balance
    state =
      initial_accounts
      |> Enum.into(%{}, fn
        {acc, bal} when is_atom(acc) and is_number(bal) -> {acc, bal}
        _ -> nil
      end)
      |> Enum.reject(&is_nil/1)
      |> Enum.into(%{})

    {:ok, state}
  end

  @impl true
  def handle_call({:deposit, who, amount}, _from, state) do
    bal = Map.get(state, who)
    if bal != nil do
      new_bal = bal + amount
      {:reply, {:ok, new_bal}, Map.put(state, who, new_bal)}
    else
      {:reply, {:error, :not_found}, state}
    end
  end

  def handle_call({:withdraw, who, amount}, _from, state) do
    bal = Map.get(state, who)
    if bal != nil do
        new_bal = bal - amount
        if new_bal >= 0 do
          {:reply, {:ok, new_bal}, Map.put(state, who, new_bal)}
        else
          {:reply, {:error, :insufficient_funds}, state}
        end
    else
      {:reply, {:error, :not_found}, state}
    end
  end

  def handle_call({:ask, who}, _from, state) do
    case Map.fetch(state, who) do
      {:ok, bal} -> {:reply, {:ok, bal}, state}
      :error -> {:reply, {:error, :not_found}, state}
    end
  end

  @impl true
  def terminate(_reason, _state), do: :ok
end
