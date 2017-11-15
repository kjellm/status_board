defmodule StatusBoard do

  alias StatusBoard.Statistics

  def hello() do
    :world
  end

  def init() do
    pid = spawn(StatusBoard.GithubIssues, :foo, [])
    Process.register(pid, :open_bugs)
    pid = spawn(StatusBoard.GithubIssues, :bar, [])
    Process.register(pid, :closed_bugs)
  end

  def open_bugs_fns do
    open_bugs()
    |> Enum.map(&(&1.duration))
    |> Statistics.five_number_summary
  end

  def closed_bugs_fns do
    closed_bugs()
    |> Enum.map(&(&1.duration))
    |> Statistics.five_number_summary
  end

  def open_bugs() do
    pid = Process.whereis(:open_bugs)
    send pid, {self(), :get}
    receive do
      {:ok, bugs} -> bugs
    end
  end

  def closed_bugs() do
    pid = Process.whereis(:closed_bugs)
    send pid, {self(), :get}
    receive do
      {:ok, bugs} -> bugs
    end
  end
end

defmodule StatusBoard.GithubIssue do
  defstruct [:title, :created_at, :closed_at, :duration]
end

defmodule StatusBoard.GithubIssues do

  alias StatusBoard.GithubAPI, as: API
  alias StatusBoard.GithubIssue

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
      %GithubIssue{
        title: i["title"],
        created_at: created_at,
        closed_at: closed_at,
        duration: diff(closed_at, created_at)
      }
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

  defp handle_open(%{"data" => %{"repository" => %{"issues" => %{"pageInfo" => %{"hasNextPage" => false}, "edges" => edges }}}}) do
    { to_open_issues(edges), :halt }
  end

  defp handle_open(%{"data" => %{"repository" => %{"issues" => %{"pageInfo" => %{"hasNextPage" => true}, "edges" => edges }}}}) do
    { to_open_issues(edges), List.last(edges)["cursor"] }
  end

  defp to_open_issues(edges) do
    today = DateTime.utc_now()
    Enum.map(edges,
      fn(e) ->
        i = e["node"]
        created_at = API.parse_datetime(i["createdAt"])
        %GithubIssue{
          title: i["title"],
          created_at: created_at,
          duration: diff(today, created_at)
        }
      end)
  end

  @seconds_in_a_day 86_400

  defp diff(%DateTime{} = dt1, %DateTime{} = dt2) do
    DateTime.diff(dt1, dt2) / (@seconds_in_a_day) |> Float.round(2)
  end

  defp diff(_, _) do
    nil
  end

  defp closed_at(timeline) do
    Enum.map(timeline["nodes"], fn(i) -> i["createdAt"] end)
    |> Enum.reject(&is_nil/1)
    |> List.first
  end

  def foo(issues \\ []) do
    issues = _foo(issues)
    receive do
      {sender, :get} -> send sender, {:ok, issues}
    end
    foo(issues)
  end

  defp _foo([]) do
    open_bugs() |> Enum.to_list
  end

  defp _foo(issues), do: issues

  def bar(issues \\ []) do
    issues = _bar(issues)
    receive do
      {sender, :get} -> send sender, {:ok, issues}
    end
    bar(issues)
  end

  defp _bar([]) do
    closed_bugs() |> Enum.to_list
  end

  defp _bar(issues), do: issues

end
