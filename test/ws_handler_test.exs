defmodule PusherClient.WSHandlerTest do
  use ExUnit.Case
  alias PusherClient.PusherEvent
  alias PusherClient.WSHandler.WSHandlerInfo
  import :meck
  import PusherClient.WSHandler

  setup do
    new JSEX
    new PusherEvent
  end

  teardown do
    unload JSEX
    unload PusherEvent
  end

  test "init" do
    assert init(self, :conn_state) == { :ok, WSHandlerInfo.new(gen_event_pid: self) }
  end

  test "handle connection established event" do
    state = WSHandlerInfo.new(gen_event_pid: self)
    socket_id = "87381"
    event = [
              { "event", "pusher:connection_established" },
              { "data", [ { "socket_id", socket_id } ] }
            ]
    expect(JSEX, :decode!, 1, event)

    assert websocket_handle({:text, :event}, :conn_state, state) ==
      { :ok, WSHandlerInfo.new(gen_event_pid: self, socket_id: socket_id) }

    assert validate JSEX
  end

  test "handle subscription succeeded event" do
    channel = "public-channel"
    event = [
              { "event", "pusher_internal:subscription_succeeded" },
              { "data", [ { "channel", channel } ] }
            ]
    expect(JSEX, :decode!, 1, event)

    assert websocket_handle({:text, :event}, :conn_state, :state) ==
      { :ok, :state }

    assert validate JSEX
  end

  test "handle other events" do
    state = WSHandlerInfo.new(gen_event_pid: self)
    channel = "public-channel"
    event = [
              { "event", "message" },
              { "channel", channel },
              { "data", [ { "etc", "anything" } ] }
            ]
    expect(JSEX, :decode!, 1, event)

    assert websocket_handle({:text, :event}, :conn_state, state) ==
      { :ok, state }

    assert validate JSEX
  end

  test "subscribe to a channel" do
    expect(PusherEvent, :subscribe, 1, :event_subscribe_json)

    assert websocket_info({ :subscribe, "channel" }, :conn_state, :state) ==
      { :reply, { :text, :event_subscribe_json}, :state }

    assert validate PusherEvent
  end

  test "unsubscribe from a channel" do
    expect(PusherEvent, :unsubscribe, 1, :event_unsubscribe_json)

    assert websocket_info({ :unsubscribe, "channel" }, :conn_state, :state) ==
      { :reply, { :text, :event_unsubscribe_json}, :state }

    assert validate PusherEvent
  end

end
