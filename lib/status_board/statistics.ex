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

  Inter quartile range

  """
  def iqr({ _, quart1, _, quart3, _}) do
    quart3 - quart1
  end

  def five_number_summary_with_outliers([]), do: nil
  def five_number_summary_with_outliers(list) do
    slist = Enum.sort(list)
    fns = five_number_summary(slist)
    { q0, q1, m, q3, q4} = fns
    iqr = iqr(fns)
    limit = iqr * 1.5
    min = Enum.find slist, fn(x) -> x >= q1 - limit end
    max = slist |> Enum.reverse |> Enum.find(slist, fn(x) -> x <= q3 + limit end)
    { {min, q1, m, q3, max}, {q0, q4}, Enum.sort(outliers(list, fns)) }
  end

  defp outliers(list, fns) do
    iqr = iqr(fns)
    limit = iqr * 1.5
    Enum.filter(list, fn(x) -> x > elem(fns, 3) + limit || x < elem(fns, 1) - limit end)
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
