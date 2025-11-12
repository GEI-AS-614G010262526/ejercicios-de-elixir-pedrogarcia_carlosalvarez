defmodule Gestor do

  def start(recursos) do
    pid = spawn(fn -> init(recursos) end)
    :global.register_name(:gestor, pid)
    :ok
  end

  def alloc() do
    #nodo_gestor = {:gestor, nodo_gestor()}
    send(:global.whereis_name(:gestor), {:alloc, self()})
    receive do
      {:ok, r} ->
        IO.puts("Recurso asignado")

      {:error, :sin_recursos} ->
        IO.puts("Error: Sin recursos")
    end
  end

  def release(recurso) do
    #nodo_gestor = {:gestor, nodo_gestor()}
    send(:global.whereis_name(:gestor), {:release, self(), recurso})
    receive do
      :ok ->
        IO.puts("Recursos liberado")

      {:error, :recurso_no_reservado} ->
        IO.puts("Error: Recurso no reservado")
    end
  end

  def avail() do
    #nodo_gestor = {:gestor, nodo_gestor()}
    send(:global.whereis_name(:gestor), {:avail, self()})
    receive do
      {:respuesta, l} ->
        IO.puts("#{l} recursos disponibles")
    end
  end

  defp init(recursos) do
    gestionar(recursos, %{})
  end

  defp gestionar(disponibles, reservados) do
    receive do
      {:alloc, from} ->
        case disponibles do
          [r | resto] ->
            nuevos_reservados = Map.update(reservados, from, [r], fn lista -> [r | lista] end)
            send(from, {:ok, r})
            gestionar(resto, nuevos_reservados)
          [] ->
            send(from, {:error, :sin_recursos})
            gestionar(disponibles, reservados)
        end

        {:release, from, recurso} ->
          case Map.get(reservados, from, []) do
            recursos->
              if recurso in recursos do
                nuevos_reservados = Map.update!(reservados, from, fn lista -> List.delete(lista, recurso) end)
                nuevos_reservados =
                  if nuevos_reservados[from] == [] do
                    Map.delete(nuevos_reservados, from)
                  else
                    nuevos_reservados
                  end

                send(from, :ok)
                gestionar([recurso | disponibles], nuevos_reservados)
              else
                send(from, {:error, :recurso_no_reservado})
                gestionar(disponibles, reservados)
              end
          end

        {:avail, from} ->
          send(from, {:respuesta, length(disponibles)})
          gestionar(disponibles, reservados)
        end
    end

  defp nodo_gestor() do
    :"gestor_node@carlos-Katana-15-B13VFK"
  end

end
