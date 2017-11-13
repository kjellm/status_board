defmodule StatusBoard.Statistics do

  @doc """

    ## Examples

      iex> StatusBoard.Statistics.five_number_summary([1,2,3])
      {1, 1.5, 2, 2.5, 3}

      iex> StatusBoard.Statistics.five_number_summary([1,2,3,4])
      {1, 1.5, 2.5, 3.5, 4}

      iex> StatusBoard.Statistics.five_number_summary([1,2,3,4,5])
      {1, 2, 3, 4, 5}

  """
  def five_number_summary([]), do: nil
  def five_number_summary(list) do
    { min(list),
      first_quartile(list),
      median(list),
      third_quartile(list),
      max(list),
    }
  end

  def min([]), do: nil
  def min(list) do
    Enum.min(list)
  end

  def max([]), do: nil
  def max(list) do
    Enum.max(list)
  end

  def median([]), do: nil
  def median([e]), do: e
  def median(list) do
    mid = div(length(list), 2)
    case rem(length(list), 2) do
      0 -> (Enum.at(list, mid-1) + Enum.at(list, mid)) / 2
      1 -> Enum.at(list, mid)
    end
  end

  def first_quartile(list) do
    {sublist, rest} = list |> Enum.split(div(length(list), 2))
    case rem(length(list), 2) do
      0 -> median(sublist)
      1 -> median(sublist ++ [List.first(rest)])
    end
  end

  def third_quartile(list) do
    {_, sublist} = list |> Enum.split(div(length(list), 2))
    median(sublist)
  end

end
