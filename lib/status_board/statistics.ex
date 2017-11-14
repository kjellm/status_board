defmodule StatusBoard.Statistics do

  @doc """

    ## Examples

      iex> StatusBoard.Statistics.five_number_summary([1,2,3])
      {1, 1.5, 2, 2.5, 3}

      iex> StatusBoard.Statistics.five_number_summary([1,2,3,4])
      {1, 1.5, 2.5, 3.5, 4}

      iex> StatusBoard.Statistics.five_number_summary([1,2,3,4,5])
      {1, 2, 3, 4, 5}

      iex> StatusBoard.Statistics.five_number_summary(Enum.shuffle([1,2,3,4,5]))
      {1, 2, 3, 4, 5}

  """
  def five_number_summary([]), do: nil
  def five_number_summary(list) do
    slist = Enum.sort(list)
    { List.first(slist),
      _first_quartile(slist),
      _median(slist),
      _third_quartile(slist),
      List.last(slist),
    }
  end

  @doc """

    ## Examples

      iex> StatusBoard.Statistics.median([1])
      1

      iex> StatusBoard.Statistics.median([1,2])
      1.5

      iex> StatusBoard.Statistics.median([1,2,3])
      2

  """
  def median(list), do: Enum.sort(list) |> _median

  defp _median([]), do: nil
  defp _median(list) do
    mid = div(length(list), 2)
    case rem(length(list), 2) do
      0 -> (Enum.at(list, mid-1) + Enum.at(list, mid)) / 2
      1 -> Enum.at(list, mid)
    end
  end

  def first_quartile(list), do: Enum.sort(list) |> _first_quartile

  defp _first_quartile(list) do
    {sublist, rest} = list |> Enum.split(div(length(list), 2))
    case rem(length(list), 2) do
      0 -> median(sublist)
      1 -> median(sublist ++ [List.first(rest)])
    end
  end

  def third_quartile(list), do: Enum.sort(list) |> _third_quartile

  defp _third_quartile(list) do
    {_, sublist} = list |> Enum.split(div(length(list), 2))
    median(sublist)
  end

end
