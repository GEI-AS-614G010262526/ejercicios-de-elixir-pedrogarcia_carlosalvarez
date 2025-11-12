defmodule GestorIt3 do
  def start(recursos) do
    pid = spawn(fn -> init(recursos) end)
    :global.register_name(:gestor, pid)
    :ok
  end

  def alloc() do
    send(:global.whereis_name(:gestor), {:alloc, self()})
    receive do
      {:ok, r} ->
        IO.puts("Recurso #{r} asignado")

      {:error, :sin_recursos} ->
        IO.puts("Error: Sin recursos")
    end
  end

  def release(recurso) do
    send(:global.whereis_name(:gestor), {:release, self(), recurso})
    receive do
      :ok ->
        IO.puts("Recursos liberado")

      {:error, :recurso_no_reservado} ->
        IO.puts("Error: Recurso no reservado")
    end
  end

  def avail() do
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
            nuevos_reservados =
              case Map.get(reservados, from) do
                nil ->
                  ref=Process.monitor(from)
                  Map.put(reservados, from, {[r], ref})

                {lista, ref} ->
                  #Map.update(reservados, from, {[r], referencia}, fn {lista, referencia} -> {[r | lista], referencia} end)
                  Map.put(reservados, from, {[r | lista], ref})
            end

            send(from, {:ok, r})
            gestionar(resto, nuevos_reservados)
          [] ->
            send(from, {:error, :sin_recursos})
            gestionar(disponibles, reservados)
        end

      {:release, from, recurso} ->
        case Map.get(reservados, from, []) do
          {recursos, ref}->
            if recurso in recursos do
              nuevos_reservados = List.delete(recursos, recurso)
              if nuevos_reservados == [] do
                Process.demonitor(ref)
                Map.delete(reservados, from)
              else
                Map.update!(reservados, from, fn {_, ref} -> {nuevos_reservados, ref} end)
              end

              send(from, :ok)
              gestionar([recurso | disponibles], nuevos_reservados)
            else
              send(from, {:error, :recurso_no_reservado})
              gestionar(disponibles, reservados)
            end

          [] ->
            send(from, {:error, :recurso_no_reservado})
            gestionar(disponibles, reservados)
        end

      {:avail, from} ->
        send(from, {:respuesta, length(disponibles)})
        gestionar(disponibles, reservados)

      {:DOWN, _ref, :process, pid, _reason} ->
        case Map.pop(reservados, pid) do
          {nil, nuevos_reservados} ->
            gestionar(disponibles, nuevos_reservados) # No había recursos

          {{recursos, _}, nuevos_reservados} ->
            # Solo usamos la lista de recursos para concatenar
            gestionar(recursos ++ disponibles, nuevos_reservados)
        end
    end
  end
end
