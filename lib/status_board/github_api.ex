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
