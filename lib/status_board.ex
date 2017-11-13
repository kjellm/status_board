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

  def call(query, variables) do
    encode(query, variables)
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

  defp encode(query_str, variables) do
    JSON.encode!(%{query: query_str, variables: variables})
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

defmodule StatusBoard.GithubIssues do

  alias StatusBoard.GithubAPI, as: API
  alias StatusBoard.Statistics

  def closed_bugs do
    query = """
      query closedIssues($owner: String!, $name: String!, $cursor: String) {
        repository(owner: $owner, name: $name) {
          issues(first: 50, after: $cursor, labels: ["bug"], states: [CLOSED]) {
            totalCount
            pageInfo { hasNextPage }
            edges {
              cursor
              node {
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
      }
    """
    Stream.resource(
      fn -> nil end,
      fn
        (:halt) ->
          {:halt, nil}
        (cursor) ->
          API.call(query, %{owner: "gramo-org", name: "echo", cursor: cursor}) |> handle_closed
      end,
      fn _ -> nil end
    )
  end

  def closed_bugs_fns do
    closed_bugs()
    |> Enum.to_list
    |> Enum.map(&(elem(&1, 3)))
    |> Enum.sort
    |> Statistics.five_number_summary
  end

  defp handle_closed(%{"data" => %{"repository" => %{"issues" => %{"pageInfo" => %{"hasNextPage" => false}, "edges" => edges }}}}) do
    {to_closed_issues(edges), :halt}
  end
  defp handle_closed(%{"data" => %{"repository" => %{"issues" => %{"pageInfo" => %{"hasNextPage" => true}, "edges" => edges }}}}) do
    {to_closed_issues(edges), List.last(edges)["cursor"] }
  end

  defp to_closed_issues(edges) do
    Enum.map(edges, fn(e) ->
      i = e["node"]
      created_at = API.parse_datetime(i["createdAt"])
      closed_at  = API.parse_datetime(closed_at(i["timeline"]))
      duration = diff(closed_at, created_at)
      { i["title"], created_at, closed_at, duration }
      end)
  end

  def open_bugs do
    query = """
      query openIssues($owner: String!, $name: String!, $cursor: String) {
        repository(owner: $owner, name: $name) {
          issues(first: 50, after: $cursor, labels: ["bug"], states: [OPEN]) {
            totalCount
            pageInfo { hasNextPage }
            edges {
              cursor
              node {
                title
                createdAt
              }
            }
          }
        }
      }
    """
    Stream.resource(
      fn -> nil end,
      fn
        (:halt) ->
          {:halt, nil}
        (cursor) ->
          API.call(query, %{owner: "gramo-org", name: "echo", cursor: cursor}) |> handle_open
      end,
      fn _ -> nil end
    )
  end

  def open_bugs_fns do
    open_bugs()
    |> Enum.to_list
    |> Enum.map(&(elem(&1, 2)))
    |> Enum.sort
    |> Statistics.five_number_summary
  end

  defp handle_open(%{"data" => %{"repository" => %{"issues" => %{"pageInfo" => %{"hasNextPage" => false}, "edges" => edges }}}}) do
    { to_open_issues(edges), :halt }
  end

  defp handle_open(%{"data" => %{"repository" => %{"issues" => %{"pageInfo" => %{"hasNextPage" => true}, "edges" => edges }}}}) do
    { to_open_issues(edges), List.last(edges)["cursor"] }
  end

  defp to_open_issues(edges) do
    Enum.map(edges,
      fn(e) ->
        i = e["node"]
        created_at = API.parse_datetime(i["createdAt"])
        today = DateTime.utc_now()
        duration = diff(today, created_at)
        { i["title"], created_at, duration }
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
