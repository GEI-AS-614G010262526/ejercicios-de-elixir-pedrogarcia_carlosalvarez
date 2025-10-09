defmodule Eratostenesconc do
  @moduledoc """
  Documentation for `Eratostenesconc`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Eratostenesconc.hello()
      :world

  """

  defp crear_filtro(primo) do
    spawn(fn -> filtrar(primo, nil) end)
  end

  defp filtrar(primo, siguiente) do
    receive do
      {:numero, n} ->
        if rem(n, primo) != 0 do
          if siguiente do
            send(siguiente, {:numero, n})
            filtrar(primo, siguiente)
          else
            IO.puts("Primo encontrado: #{n}")
            nuevo_filtro = crear_filtro(n)
            filtrar(primo, nuevo_filtro)
          end
        else
          filtrar(primo, siguiente)
        end

      :fin ->
        if siguiente do
          send(siguiente, :fin)
        end

        exit(:normal)
    end
  end

  def enviar_numeros(limite, pid) do
    Enum.each(2..limite, fn n ->
      #IO.puts("Enviando número: #{n}")
      send(pid, {:numero, n}) end)
    send(pid, :fin)
  end

  def ejecutar(limite) do
    pid = crear_filtro(2)
    enviar_numeros(limite, pid)
  end

end
