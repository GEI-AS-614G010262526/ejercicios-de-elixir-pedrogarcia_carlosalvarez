defmodule ServerSupervisor do
  @moduledoc """
  Supervisor que proporciona tolerancia a fallos para el Server.

  start_link(initial_accounts \\ []) arranca el supervisor y pasa
  las cuentas iniciales al Server. Si el Server falla, el supervisor
  lo reiniciará (strategy: :one_for_one, restart: :permanent).
  """

  use Supervisor

  @spec start_link(list({atom(), number()})) :: {:ok, pid()}
  def start_link(initial_accounts \\ []) when is_list(initial_accounts) do
    Supervisor.start_link(__MODULE__, initial_accounts, name: __MODULE__)
  end

  @impl true
  def init(initial_accounts) when is_list(initial_accounts) do
    children = [
      %{
        id: Server,
        start: {Server, :start_link, [initial_accounts]},
        restart: :transient,
        shutdown: 5_000,
        type: :worker
      }
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
