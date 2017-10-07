defmodule PusherClient.Mixfile do
  use Mix.Project

  def project do
    [ app: :pusher_client,
      version: "1.0.0",
      elixir: "~> 1.5",
      deps: deps() ]
  end

  def application do
    [ applications: [ :logger, :websocket_client, :poison ] ]
  end

  defp deps do
    [ { :websocket_client, "~> 1.3" },
      { :poison, "~> 3.0" },
      { :meck, "~> 0.8", only: :test } ]
  end
end
