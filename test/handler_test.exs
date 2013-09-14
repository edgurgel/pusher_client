defmodule PusherClient.HandlerTest do
  use ExUnit.Case
  alias PusherClient.PusherEvent
  import :meck
  import PusherClient.Handler

  setup do
    new JSEX
    new PusherEvent
  end

  teardown do
    unload JSEX
    unload PusherEvent
  end

  test "init" do
    assert init(:args, :conn_state) == { :ok, nil }
  end

  test "handle connection established event" do
    socket_id = "87381"
    event = [
              { "event", "pusher:connection_established" },
              { "data", [ { "socket_id", socket_id } ] }
            ]
    expect(JSEX, :decode!, 1, event)

    assert websocket_handle({:text, :event}, :conn_state, :state) ==
      { :ok, socket_id }

    assert validate JSEX
  end

  test "handle subscription succeeded event" do
    channel = "public-channel"
    event = [
              { "event", "pusher_internal:subscription_succeeded" },
              { "data", [ { "channel", channel } ] }
            ]
    expect(JSEX, :decode!, 1, event)

    assert websocket_handle({:text, :event}, :conn_state, :socket_id) ==
      { :ok, :socket_id }

    assert validate JSEX
  end

  test "subscribe event" do
    expect(PusherEvent, :subscribe, 1, :event_subscribe_json)

    assert websocket_info({ :subscribe, "channel" }, :conn_state, :socket_id) ==
      { :reply, { :text, :event_subscribe_json}, :socket_id }

    assert validate PusherEvent
  end

  test "unsubscribe event" do
    expect(PusherEvent, :unsubscribe, 1, :event_unsubscribe_json)

    assert websocket_info({ :unsubscribe, "channel" }, :conn_state, :socket_id) ==
      { :reply, { :text, :event_unsubscribe_json}, :socket_id }

    assert validate PusherEvent
  end

end
