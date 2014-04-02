defmodule PusherClientTest do
  use ExUnit.Case
  import :meck
  import PusherClient


  setup do
    new :websocket_client
  end

  teardown do
    unload :websocket_client
  end

  test "connect to an url using Elixir string" do
    expect(:websocket_client, :start_link, [{['http://websocket.example?protocol=7', PusherClient.WSHandler, :_], { :ok, :ws_pid }}])

    {:ok, _pid} = connect!("http://websocket.example")

    assert validate :websocket_client
  end

  test "connect to an url using Erlang string" do
    expect(:websocket_client, :start_link, [{['http://websocket.example?protocol=7', PusherClient.WSHandler, :_], { :ok, :ws_pid }}])

    {:ok, _pid} = connect!('http://websocket.example')

    assert validate :websocket_client
  end
end
