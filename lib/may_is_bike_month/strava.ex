defmodule MayIsBikeMonth.Strava do
  def authorize_url() do
    "http://www.strava.com/oauth/authorize?client_id=#{client_id()}&response_type=code&scope=activity:read_all,profile:read_all&redirect_uri=#{redirect_uri()}"
  end

  def exchange_access_token(opts) do
    Keyword.fetch!(opts, :code)
    |> fetch_exchange_response()
  end

  defp fetch_exchange_response(code) do
    HTTPoison.start()
    body = Jason.encode!(%{code: code, client_secret: secret(), client_id: client_id()})

    tuple_response(
      HTTPoison.post(token_url("authorization_code"), body, [{"Content-Type", "application/json"}])
    )
  end

  def refresh_access_token(refresh_token) do
    HTTPoison.start()

    body =
      Jason.encode!(%{
        refresh_token: refresh_token,
        client_secret: secret(),
        client_id: client_id()
      })

    tuple_response(
      HTTPoison.post(token_url("refresh_token"), body, [{"Content-Type", "application/json"}])
    )
  end

  def get_activities(access_token, parameters \\ %{}) do
    HTTPoison.start()
    url = "https://www.strava.com/api/v3/athlete/activities?#{URI.encode_query(parameters)}"
    headers = [{"Authorization", "Bearer #{access_token}"}, {"Content-Type", "application/json"}]
    tuple_response(HTTPoison.get(url, headers))
  end

  defp token_url(grant_type), do: "https://www.strava.com/oauth/token?grant_type=#{grant_type}"

  defp client_id, do: MayIsBikeMonth.config([:strava, :client_id])
  defp secret, do: MayIsBikeMonth.config([:strava, :client_secret])
  defp redirect_uri, do: "#{redirect_domain()}/oauth/callbacks/strava"
  defp redirect_domain, do: MayIsBikeMonth.config([:strava, :redirect_domain])

  defp tuple_response(resp) do
    case resp do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, Jason.decode!(body)}

      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        {:error, %{status: status_code, body: Jason.decode!(body)}}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, %{status: 0, body: reason}}
    end
  end
end
