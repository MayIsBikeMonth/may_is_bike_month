# frozen_string_literal: true

module StravaIntegration
  extend Functionable

  CLIENT_ID = ENV["STRAVA_CLIENT_ID"]
  SECRET = ENV["STRAVA_SECRET"]
  STRAVA_BASE_URL = "https://www.strava.com"

  def webhook_verify_token
    ENV["STRAVA_WEBHOOK_VERIFY_TOKEN"]
  end

  def refresh_access_token(refresh_token)
    response = connection.post(token_path("refresh_token")) do |req|
      req.body = {refresh_token:, client_secret: SECRET, client_id: CLIENT_ID}.to_json
    end
    {json: JSON.parse(response.body), status: response.status}.with_indifferent_access
  end

  def get_activities(access_token, parameters: {})
    response = athlete_connection(access_token).get("/api/v3/athlete/activities?#{parameters.to_query}")
    {json: JSON.parse(response.body), status: response.status}.with_indifferent_access
  end

  def create_webhook_subscription
    response = form_connection.post("/api/v3/push_subscriptions") do |req|
      req.body = {
        client_id: CLIENT_ID,
        client_secret: SECRET,
        callback_url: Rails.application.routes.url_helpers.strava_webhooks_url,
        verify_token: webhook_verify_token
      }
    end
    {json: JSON.parse(response.body), status: response.status}.with_indifferent_access
  end

  def view_webhook_subscriptions
    response = form_connection.get("/api/v3/push_subscriptions") do |req|
      req.params = {client_id: CLIENT_ID, client_secret: SECRET}
    end
    {json: JSON.parse(response.body), status: response.status}.with_indifferent_access
  end

  def delete_webhook_subscription(subscription_id)
    response = form_connection.delete("/api/v3/push_subscriptions/#{subscription_id}") do |req|
      req.params = {client_id: CLIENT_ID, client_secret: SECRET}
    end
    {status: response.status}.with_indifferent_access
  end

  #
  # private below here
  #

  def connection
    Faraday.new(url: STRAVA_BASE_URL) do |conn|
      conn.adapter Faraday.default_adapter
      conn.headers["Content-Type"] = "application/json"
    end
  end

  def athlete_connection(access_token)
    Faraday.new(url: STRAVA_BASE_URL) do |conn|
      conn.adapter Faraday.default_adapter
      conn.headers["Content-Type"] = "application/json"
      conn.headers["Authorization"] = "Bearer #{access_token}"
    end
  end

  def form_connection
    Faraday.new(url: STRAVA_BASE_URL) do |conn|
      conn.request :url_encoded
      conn.adapter Faraday.default_adapter
    end
  end

  def token_path(grant_type)
    "/oauth/token?grant_type=#{grant_type}"
  end

  def redirect_uri
    "#{ENV.fetch("BASE_URL", "https://mayisbikemonth.org")}/oauth/callbacks/strava"
  end

  conceal :connection, :athlete_connection, :form_connection, :token_path, :redirect_uri
end
