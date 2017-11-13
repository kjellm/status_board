defmodule StatusBoard do
  def hello() do
    :world
  end
end

defmodule StatusBoard.HTTPClient do
  def post!(url, body, headers) do
    HTTPoison.post!(url, body, headers)
  end
end

defmodule StatusBoard.JSON do

  def encode!(str) do
    Poison.encode!(str)
  end

  def decode!(data) do
    Poison.decode!(data)
  end

end

defmodule StatusBoard.GithubAPI do

  alias StatusBoard.HTTPClient
  alias StatusBoard.JSON

  @url "https://api.github.com/graphql"

  def call(query) do
    encode(query)
    |> fetch()
    |> decode()
  end

  defp fetch(body) do
    HTTPClient.post!(@url, body, headers())
  end

  defp headers do
    token = System.get_env("GITHUB_API_TOKEN")
    [
      {"User-agent", "https://github.com/kjellm/status_board"},
      {"Authorization", "Bearer #{token}"}
    ]
  end

  defp encode(query_str) do
    JSON.encode!(%{query: query_str})
  end

  defp decode(%{body: body}) do
    JSON.decode!(body)
  end

  def parse_datetime(string) do
    case DateTime.from_iso8601(string) do
      { :ok, date, 0 } -> date
      { :error, reason } -> { reason, string }
    end
  end

end

defmodule StatusBoard.Statistics do

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

defmodule StatusBoard.GithubIssues do

  alias StatusBoard.GithubAPI, as: API
  alias StatusBoard.Statistics

  def closed_bugs do
    query = """
      {
        repository(owner: "gramo-org", name: "echo") {
          issues(first: 50, labels: ["bug"], states: [CLOSED]) {
            nodes {
              id
              title
              createdAt
              timeline(last: 30) {
                 nodes {
                  ... on ClosedEvent {
                    createdAt
                  }
                }
              }
            }
          }
        }
      }
    """
    API.call(query)
    |> handle_closed
  end

  def closed_bugs_fns do
    closed_bugs()
    |> Enum.map(&(elem(&1, 4)))
    |> Enum.sort
    |> Statistics.five_number_summary
  end

  defp handle_closed(%{"data" => %{"repository" => %{"issues" => %{"nodes" => issues}}}}) do
    Enum.map(issues, fn(i) ->
      created_at = API.parse_datetime(i["createdAt"])
      closed_at  = API.parse_datetime(closed_at(i["timeline"]))
      duration = diff(closed_at, created_at)
      { i["id"], i["title"], created_at, closed_at, duration }
      end)
  end

  def open_bugs do
    query = """
      {
        repository(owner: "gramo-org", name: "echo") {
          issues(first: 50, labels: ["bug"], states: [OPEN]) {
            nodes {
              id
              title
              createdAt
            }
          }
        }
      }
    """
    API.call(query)
    |> handle_open
  end

  def open_bugs_fns do
    open_bugs()
    |> Enum.map(&(elem(&1, 3)))
    |> Enum.sort
    |> Statistics.five_number_summary
  end

  defp handle_open(%{"data" => %{"repository" => %{"issues" => %{"nodes" => issues}}}}) do
    Enum.map(issues, fn(i) ->
      created_at = API.parse_datetime(i["createdAt"])
      today = DateTime.utc_now()
      duration = diff(today, created_at)
      { i["id"], i["title"], created_at, duration }
      end)
  end

  defp diff(%DateTime{} = dt1, %DateTime{} = dt2) do
    DateTime.diff(dt1, dt2) / (60*60*24)
  end

  defp diff(_, _) do
    nil
  end

  defp closed_at(timeline) do
    Enum.map(timeline["nodes"], fn(i) -> i["createdAt"] end)
    |> Enum.reject(&is_nil/1)
    |> List.first
  end
end
