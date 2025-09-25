defmodule Eratostenes do
  @moduledoc """
  Documentation for `Eratostenes`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Eratostenes.hello()
      :world

  """
  defp filto(p) do
    receive do
      [h|t] ->


    end
  end

  defp filtro(p, g) do
    receive do
      [h|t] ->
        send(g, [h|t]  |> Enum.reject(fn x -> rem(x, h) == 0 end))

    end
  end

end
