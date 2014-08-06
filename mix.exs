defmodule PusherClient.Mixfile do
  use Mix.Project

  def project do
    [ app: :pusher_client,
      version: "0.0.1",
      elixir: "~> 0.14.1 or ~> 0.15.0",
      deps: deps ]
  end

  def application do
    [ applications: [ :exlager ] ]
  end

  defp deps do
    [ { :websocket_client, github: "jeremyong/websocket_client" },
      { :exlager, github: "khia/exlager" },
      { :jsex, "~> 2.0" },
      { :meck, github: "eproxus/meck", tag: "0.8.2", only: :test } ]
  end
end
