defmodule Server_Script do
  @moduledoc """
  Utilidades para crear nodos/esclavos y arrancar un único Server por nodo,
  además de poblarlos con actores iniciales para tests.

  Ejemplos:
    {:ok, node} = ServidoresFederados.Script.start_node(:enterprise, [{:spock, %{name: "Spock", avatar: "url"}}])
    :ok = ServidoresFederados.Script.stop_node(node)

  Notas:
  - Cada nodo arrancado con `start_node/2` tendrá exactamente un Server (si no existe ya).
  - El nombre federado del servidor coincide con el nombre del nodo (el átomo que pases).
  """

  @doc "Arranca un nodo esclavo llamado `name` y arranca Server con `initial_actors`."
  @spec start_node(atom(), list()) :: {:ok, node()} | {:error, any()}
  def start_node(name, initial_actors \\ []) when is_atom(name) and is_list(initial_actors) do
    host = get_local_hostname()

    # arrancar el nodo esclavo
    case :slave.start(host, name, slave_opts()) do
      {:ok, node} ->
        add_code_paths(node)
        ensure_applications(node)
        start_server_on(node, initial_actors)

      error ->
        error
    end
  end

  @doc "Arranca varios nodos especificados como [{name, initial_actors}, ...]."
  @spec start_nodes(list({atom(), list()})) :: [{atom(), {:ok, node()} | {:error, any()}}]
  def start_nodes(specs) when is_list(specs) do
    Enum.map(specs, fn {name, actors} -> {name, start_node(name, actors)} end)
  end

  @doc "Detiene el nodo esclavo."
  @spec stop_node(node()) :: :ok | {:error, any()}
  def stop_node(node) when is_atom(node) do
    :slave.stop(node)
  end

  @doc "Lista nodos esclavos conocidos (Node.list/0)."
  @spec list_nodes() :: [node()]
  def list_nodes do
    Node.list()
  end

  @spec start_example_nodes() :: list({atom(), {:ok, node()} | {:error, any()}})
  def start_example_nodes do
    specs = [
      {:alice_node, [
         {:alice, %{name: "Alice", avatar: "https://example.com/alice.png"}},
         {:bob,   %{name: "Bob",   avatar: "https://example.com/bob.png"}}
       ]},
      {:charlie_node, [
         {:charlie, %{name: "Charlie", avatar: "https://example.com/charlie.png"}}
       ]},
      {:diana_node, [
         {:diana, %{name: "Diana", avatar: "https://example.com/diana.png"}}
       ]}
    ]
    Enum.map(specs, fn {name, actors} -> {name, Server.start_link(actors)} end)
  end

  @doc """
  Asegura que en `node` existe un Server arrancado; si no existe lo arranca con
  `initial_actors`. Devuelve {:ok, pid} o {:error, reason}.
  """
  @spec ensure_server_started_on(node(), list()) :: {:ok, pid()} | {:error, any()}
  def ensure_server_started_on(node, initial_actors \\ []) when is_atom(node) and is_list(initial_actors) do
    case :rpc.call(node, Process, :whereis, [Server]) do
      pid when is_pid(pid) ->
        {:ok, pid}

      nil ->
        start_server_on(node, initial_actors)
    end
  end

  # Internal helpers

  defp start_server_on(node, initial_actors) do
    # start_link puede devolver {:ok, pid} o {:error, {:already_started, pid}}
    case :rpc.call(node, Server, :start_link, [initial_actors]) do
      {:ok, pid} -> {:ok, pid}
      {:error, {:already_started, pid}} -> {:ok, pid}
      other -> {:error, other}
    end
  end

  defp get_local_hostname do
    # :inet.gethostname() devuelve charlist
    case :inet.gethostname() do
      {:ok, host} -> host
      _ -> "localhost"
    end
  end

  defp slave_opts do
    # asegurar cookie igual al proceso maestro
    cookie = Atom.to_charlist(Node.get_cookie())
    ["-setcookie", cookie]
  end

  defp add_code_paths(node) do
    # Añadir los paths de código del nodo actual al nodo esclavo para que cargue módulos compilados
    for path <- :code.get_path() do
      :rpc.call(node, :code, :add_pathz, [path])
    end

    :ok
  end

  defp ensure_applications(node) do
    # arrancar aplicaciones necesarias mínimas en el nodo esclavo (logger por ejemplo)
    # Ignorar errores porque pueden ya estar arrancadas.
    :rpc.call(node, Application, :ensure_all_started, [:logger])
    :ok
  end
end
