defmodule Server do

  @spec start(integer()) :: {:ok, pid()}
  def start(n) do
    pid = spawn(fn -> init_server(n) end)
    Process.register(pid, :server)
    {:ok, pid}
  end


  @spec run_batch(pid(), list()) :: list()
  def run_batch(master, jobs) do
    send(master, {:trabajos, self(), jobs})

    receive do
      {:resultados, resultados} ->
        resultados
      end
  end


  @spec stop(pid()) :: :ok
  def stop(master) do
    send(master, :stop)
  end


  defp init_server(n) do
    workers =
      for i <- 1..n do
        Trabajador.start_work(i)
      end

    trabajar(workers)
  end

    defp trabajar(workers) do
    receive do
      {:trabajos, from, jobs} ->
        if length(workers) < length(jobs) do
          send(from, {:resultados, {:error, :lote_demasiado_grande}})
          trabajar(workers)
        else
          pid1 = spawn(fn -> cola(workers, from, jobs) end)
          trabajar(workers, from, jobs, pid1)
        end

      :stop ->
        Enum.each(workers, fn pid -> send(pid, :stop) end)

    end
  end

  defp trabajar(workers, pid) do
    receive do
      {:trabajos, from, jobs} ->
        if length(workers) < length(jobs) do
          send(from, {:resultados, {:error, :lote_demasiado_grande}})
          trabajar(workers)
        else
          pid1 = spawn(fn -> cola(workers, from, jobs, pid) end)
          trabajar(workers, from, jobs, pid1)
        end

      :stop ->
        Enum.each(workers, fn pid1 -> send(pid1, :stop) end)

    end
  end

  defp recibir_resultados(n) do
    receive do
      {:resultado, resultado} ->
        recibir_resultados(n-1, [resultado])
      end
  end

  defp recibir_resultados(0, resultados) do
    IO.puts("Ultimo receive")
    Enum.each(resultados, fn resultado -> IO.puts("#{resultado}") end)
    resultados
  end

  defp recibir_resultados(n, resultados) do
    receive do
      {:resultado, resultado} ->
        recibir_resultados(n-1, [resultado | resultados])
      end
  end

  defp cola(workers, from, jobs) do
    repartir_trabajo(workers, jobs)
    resultados = recibir_resultados(length(jobs))
    Enum.each(resultados, fn resultado -> IO.puts("#{resultado}") end)
    send(from, {:resultados, resultados})
    receive do
      {:queue, pid1} ->
        send(pid1, :clear_queue)
    end

  defp cola(workers, from, jobs, pid) do
      send(pid, {:queue, self()})
      receive do
        :clear_queue ->
          repartir_trabajo(workers, jobs)
          resultados = recibir_resultados(length(jobs))
          Enum.each(resultados, fn resultado -> IO.puts("#{resultado}") end)
          send(from, {:resultados, resultados})
          receive do
          {:queue, pid1} ->
            send(pid1, :clear_queue)
          end
      end
    end
  end

  defp repartir_trabajo([worker|rest_workers], [job|rest_jobs]) do
    send(worker, {:trabajo, self(), job})
    repartir_trabajo(rest_workers, rest_jobs)
  end

  defp repartir_trabajo([worker|rest_workers], []) do
    :ok
  end

  defp repartir_trabajo([], []) do
    :ok
  end
end
