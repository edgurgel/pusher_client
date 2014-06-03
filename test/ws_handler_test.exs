defmodule PusherClient.WSHandlerTest do
  use ExUnit.Case
  alias PusherClient.PusherEvent
  alias PusherClient.WSHandler.State
  import :meck
  import PusherClient.WSHandler

  defmodule EventHandler do
    use GenEvent.Behaviour
    def init(_), do: { :ok, [] }
    def handle_event(e, events), do: { :ok, [e|events] }
    def handle_call(:events, events), do: {:ok, Enum.reverse(events), []}
  end

  setup do
    new JSEX
    new PusherEvent
  end

  teardown do
    unload JSEX
    unload PusherEvent
  end

  test "init" do
    assert init({:gen_server_pid, :gen_event_pid}, :conn_state) ==
      { :ok, %State{gen_server_pid: :gen_server_pid, gen_event_pid: :gen_event_pid} }
  end

  test "handle connection established event" do
    state = %State{gen_event_pid: self}
    socket_id = "87381"
    event = %{
               "event" => "pusher:connection_established",
               "data" => %{ "socket_id" => socket_id }
            }
    expect(JSEX, :decode!, 1, event)

    assert websocket_handle({:text, :event}, :conn_state, state) ==
      { :ok, %State{gen_event_pid: self, socket_id: socket_id} }

    assert validate JSEX
  end

  test "handle subscription succeeded event" do
    { :ok, gen_event_pid } = :gen_event.start_link
    :gen_event.add_handler(gen_event_pid, EventHandler, [])

    state = %State{gen_event_pid: gen_event_pid}
    channel = "public-channel"
    event = %{
               "event" => "pusher_internal:subscription_succeeded",
               "channel" => channel,
               "data" => %{}
             }
    expect(JSEX, :decode!, 1, event)

    assert websocket_handle({:text, :event}, :conn_state, state) == { :ok, state }
    assert :gen_event.call(gen_event_pid, EventHandler, :events) ==
      [{"public-channel", "pusher:subscription_succeeded", %{}}]

    assert validate JSEX
  end

  test "handle other events" do
    { :ok, gen_event_pid } = :gen_event.start_link
    :gen_event.add_handler(gen_event_pid, EventHandler, [])

    state = %State{gen_event_pid: gen_event_pid}
    channel = "public-channel"
    event = %{
               "event" => "message",
               "channel" => channel,
               "data" => %{ "etc" => "anything" }
            }
    expect(JSEX, :decode!, 1, event)

    assert websocket_handle({:text, :event}, :conn_state, state) == { :ok, state }
    assert :gen_event.call(gen_event_pid, EventHandler, :events) ==
      [{"public-channel", "message", %{"etc" => "anything"}}]

    :gen_event.stop(gen_event_pid)
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

  test "terminating with error code 4001" do
    state = %State{gen_server_pid: self}

    assert websocket_terminate({ :remote, 4001, "Message" }, :conn_state, state) == :ok

    assert_received { :stop, { :remote, 4001, "Message" } }
  end

  test "terminating with error code 4007" do
    state = %State{gen_server_pid: self}

    assert websocket_terminate({ :remote, 4007, "Message" }, :conn_state, state) == :ok

    assert_received { :stop, { :remote, 4007, "Message" } }
  end

  test "terminating normally" do
    assert websocket_terminate({ :normal, "Message" }, :conn_state, nil) == :ok
  end

end
