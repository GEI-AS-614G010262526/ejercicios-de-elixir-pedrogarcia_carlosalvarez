defmodule Server do
  @moduledoc """
  GenServer que implementa un servidor federado sencillo.

  API pública (para clientes locales):
    - start_link(initial_actors \\ []) :: {:ok, pid()}
      initial_actors: lista de tuplas {user_atom, %{name: String.t(), avatar: String.t(), inbox: list()}}
      El campo :inbox es opcional.

    - get_profile(requestor, actor) ::
        {:ok, profile_map} | {:error, :not_registered} | {:error, :not_found} | {:error, reason}

    - post_message(sender, receiver, message) ::
        {:ok, :delivered} | {:error, :not_registered} | {:error, :not_found} | {:error, reason}

    - retrieve_messages(actor) ::
        {:ok, messages_list} | {:error, :not_registered} | {:error, :not_found}

  Nota sobre formatos de actor:
    - Se acepta actor como {user_atom, server_atom} o como "user@server" (string).
    - El "server" debe coincidir con el nombre del nodo objetivo (Node.self() / nodo remoto).
  """

  use GenServer

  ## Client API

  @spec start_link(list()) :: {:ok, pid()}
  def start_link(initial_actors \\ []) do
    GenServer.start_link(__MODULE__, initial_actors, name: __MODULE__)
  end

  @spec get_profile(any(), any()) :: tuple()
  def get_profile(requestor, actor) do
    GenServer.call(__MODULE__, {:get_profile, requestor, actor})
  end

  @spec post_message(any(), any(), any()) :: tuple()
  def post_message(sender, receiver, message) do
    GenServer.call(__MODULE__, {:post_message, sender, receiver, message})
  end

  @spec retrieve_messages(any()) :: tuple()
  def retrieve_messages(actor) do
    GenServer.call(__MODULE__, {:retrieve_messages, actor})
  end

  ## Server callbacks

  @impl true
  def init(initial_actors) do
    # normalizamos la lista de actores a un mapa user_atom => %{profile: ..., inbox: [...]}
    {node_name, extension} = parse_actor(to_string(Node.self()))
    actors =
      initial_actors
      |> Enum.reduce(%{}, fn
        {user, %{name: name, avatar: avatar} = _map}, acc ->
          Map.put(acc, user, %{
            profile: %{
              id: build_id(user, node_name),
              name: name,
              avatar: avatar
            },
            inbox: []
          })
        _, acc ->
          acc
      end)
    state = %{node: node_name, extension: extension, actors: actors}
    {:ok, state}
  end

  # handle client requests

  @impl true
  def handle_call({:get_profile, requestor, actor}, _from, state) do
    {_req_user, req_server} = parse_actor(requestor)
    IO.puts(state.node)
    if req_server == state.node do
      {target_user, target_server} = parse_actor(actor)
      if target_server == state.node do
        case Map.get(state.actors, target_user) do
          nil -> {:reply, {:error, :not_found}, state}
          %{profile: profile} -> {:reply, {:ok, profile}, state}
        end
      else
        # federated: forward to remote server
        remote = {__MODULE__, String.to_atom("#{target_server}@#{state.extension}")}
        # call remote server's federated API
        case GenServer.call(remote, {:federated_get_profile, state.node, target_user}, 5_000) do
          {:ok, profile} -> {:reply, {:ok, profile}, state}
          {:error, _} = err -> {:reply, err, state}
          other -> {:reply, {:error, other}, state}
        end
      end
    else
      {:reply, {:error, :not_registered}, state}
    end
  end

  @impl true
  def handle_call({:post_message, sender, receiver, message}, _from, state) do
    {s_user, s_server} = parse_actor(sender)
    if s_server == state.node do
      {r_user, r_server} = parse_actor(receiver)
      if r_server == state.node do
        case Map.get(state.actors, r_user) do
          nil ->
            {:reply, {:error, :not_found}, state}

          target ->
            timestamped = %{from: build_id(s_user, s_server), body: message, at: System.system_time(:millisecond)}
            new_target = Map.update!(target, :inbox, fn inbox -> [timestamped | inbox] end)
            new_actors = Map.put(state.actors, r_user, new_target)
            {:reply, {:ok, :delivered}, %{state | actors: new_actors}}
        end
      else
        remote = {__MODULE__, r_server}
        case GenServer.call(remote, {:federated_post_message, state.node, r_user, %{from: build_id(s_user, s_server), body: message}}, 5_000) do
          {:ok, :delivered} -> {:reply, {:ok, :delivered}, state}
          {:error, _} = err -> {:reply, err, state}
          other -> {:reply, {:error, other}, state}
        end
      end
    else
      {:reply, {:error, :not_registered}, state}
    end
  end

  @impl true
  def handle_call({:retrieve_messages, actor}, _from, state) do
    {user, server} = parse_actor(actor)
    if server == state.node do
      case Map.get(state.actors, user) do
        nil -> {:reply, {:error, :not_found}, state}
        %{inbox: inbox} = target ->
          # devolvemos y limpiamos el inbox
          new_target = Map.put(target, :inbox, [])
          new_actors = Map.put(state.actors, user, new_target)
          {:reply, {:ok, Enum.reverse(inbox)}, %{state | actors: new_actors}}
      end
    else
      {:reply, {:error, :not_registered}, state}
    end
  end

  # federated handlers (called by remote servers)

  @impl true
  def handle_call({:federated_get_profile, _from_server, target_user}, _from, state)  do
    case Map.get(state.actors, target_user) do
      nil -> {:reply, {:error, :not_found}, state}
      %{profile: profile} -> {:reply, {:ok, profile}, state}
    end
  end

  @impl true
  def handle_call({:federated_post_message, _from_server, target_user, message_map}, _from, state) do
    case Map.get(state.actors, target_user) do
      nil ->
        {:reply, {:error, :not_found}, state}

      target ->
        timestamped = Map.put(message_map, :at, System.system_time(:millisecond))
        new_target = Map.update!(target, :inbox, fn inbox -> [timestamped | inbox] end)
        new_actors = Map.put(state.actors, target_user, new_target)
        {:reply, {:ok, :delivered}, %{state | actors: new_actors}}
    end
  end

  @impl true
  def terminate(_reason, _state), do: :ok

  ## Helpers

  defp build_id(user, node) do
    # construye "user@servername" usando la parte izquierda del atom de nodo si tiene @
    node_str = Atom.to_string(node)
    server_name =
      case String.split(node_str, "@") do
        [left | _] -> left
        [] -> node_str
      end

    "#{Atom.to_string(user)}@#{server_name}"
  end

  defp parse_actor({user, server}) when is_atom(user) and is_atom(server), do: {user, server}
  defp parse_actor({user, server}) when is_binary(user) and is_binary(server), do: {String.to_atom(user), String.to_atom(server)}

  defp parse_actor(actor) do
    [user_s, server_s] = String.split(actor, "@")
    {String.to_atom(user_s), String.to_atom(server_s)}
  end
end
