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
  def primos_hasta(n) when n < 2, do: []

  def primos_hasta(n) do
    cribar(2..n|>Enum.to_list(), [])
  end

  defp cribar([], primos), do: Enum.reverse(primos)

  defp cribar([h|t], primos) do
    nuevos = Enum.reject(t, fn x -> rem(x, h) == 0 end)
    cribar(nuevos, [h|primos])
  end
end
