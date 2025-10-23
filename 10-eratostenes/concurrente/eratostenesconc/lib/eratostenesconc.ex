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
            nuevo_filtro = crear_filtro(n)
            filtrar(primo, nuevo_filtro)
          end
        else
          filtrar(primo, siguiente)
        end

        {:fin, id, list} ->
        if siguiente do
          send(siguiente, {:fin, id, [primo|list]})
        else
          IO.puts("Send de enviar numeros")
          send(id, {:lista, [primo|list]})
        end

        exit(:normal)
    end
  end

  def enviar_numeros(limite, pid) do
    Enum.each(2..limite, fn n ->
      send(pid, {:numero, n}) end)
    send(pid, {:fin, self(), []})
    receive do
      {:lista, lista} ->
        IO.puts("Receive de enviar numeros")
        Enum.reverse(lista)
    end
  end

  def primos(limite) do
    pid = crear_filtro(2)
    enviar_numeros(limite, pid)
  end

end
