defmodule PusherClient.Mixfile do
  use Mix.Project

  def project do
    [ app: :pusher_client,
      version: "0.0.1",
      elixir: "~> 0.12.2",
      deps: deps(Mix.env) ]
  end

  def application do
    [ applications: [ :exlager ] ]
  end

  defp deps(:dev) do
    [
      { :websocket_client, github: "jeremyong/websocket_client" },
      { :exlager, github: "khia/exlager"},
      { :jsex, github: "talentdeficit/jsex", ref: "c9df36f07b2089a73ab6b32074c01728f1e5a2e1" }
    ]
  end

  defp deps(:test) do
    deps(:dev) ++
     [ {:meck, github: "eproxus/meck", tag: "0.8" } ]
  end

  defp deps(_), do: deps(:dev)
end
