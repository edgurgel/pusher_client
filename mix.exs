defmodule PusherClient.Mixfile do
  use Mix.Project

  def project do
    [ app: :pusher_client,
      version: "0.0.1",
      elixir: "~> 0.10.2",
      deps: deps(Mix.env) ]
  end

  def application do
    [ applications: [ :exlager ] ]
  end

  defp deps(:dev) do
    [
      { :websocket_client, github: "jeremyong/websocket_client" },
      { :exlager, github: "edgurgel/exlager" },
      { :jsex, github: "talentdeficit/jsex" }
    ]
  end

  defp deps(:test) do
    deps(:dev) ++
     [ {:meck, github: "eproxus/meck", tag: "0.8" } ]
  end

end
