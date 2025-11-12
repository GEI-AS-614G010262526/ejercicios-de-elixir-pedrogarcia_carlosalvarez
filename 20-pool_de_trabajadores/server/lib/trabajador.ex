defmodule Trabajador do

  def start_work(worker_id) do
    spawn(fn -> work(worker_id) end)
  end

  defp work(id) do
    IO.puts("Hola, soy el trabajador #{id}")

    receive do
      {:trabajo, from, func} ->
        resultado = func.()
        send(from, {:resultado, resultado})
        work(id)

      :stop ->
        IO.puts("Trabajador #{id} deteniendose.")
        :ok

    end
  end

end
