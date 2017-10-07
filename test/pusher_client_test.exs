defmodule PusherClient.WSHandlerTest do
  use ExUnit.Case
  alias PusherClient.PusherEvent
  alias PusherClient.State
  alias PusherClient.Credential
  alias PusherClient.User
  import PusherClient
  import :meck

  defmodule EventHandler do
    use GenEvent
    def init(_), do: { :ok, [] }
    def handle_event(e, events), do: { :ok, [e|events] }
    def handle_call(:events, events), do: {:ok, Enum.reverse(events), []}
  end

  setup do
    new Poison
    new PusherEvent
    on_exit fn -> unload() end
    :ok
  end

  test "init" do
    credential = %Credential{app_key: "key", secret: "secret"}
    assert { :ok, %State{stream_to: nil, credential: ^credential} } = init(["key", "secret", []], :conn_state)
  end

  test "connect to an url using Elixir string" do
    expect(:websocket_client, :start_link, [{['http://websocket.example/app/key?protocol=7', PusherClient, ["key", "secret", []]], { :ok, :ws_pid }}])

    assert {:ok, :ws_pid} == start_link("http://websocket.example", "key", "secret")

    assert validate :websocket_client
  end

  test "connect to an url using Erlang string" do
    expect(:websocket_client, :start_link, [{['http://websocket.example/app/key?protocol=7', PusherClient, ["key", "secret", []]], { :ok, :ws_pid }}])

    assert {:ok, :ws_pid} == start_link('http://websocket.example', "key", "secret")

    assert validate :websocket_client
  end

  test "handle connection established event" do
    state = %State{stream_to: self()}
    socket_id = "87381"
    event = %{
               "event" => "pusher:connection_established",
               "data" => %{ "socket_id" => socket_id }
            }
    expect(Poison, :decode!, 1, event)
    expect(Poison, :decode, 1, {:ok, event["data"]})

    assert websocket_handle({:text, :event}, :conn_state, state) ==
      { :ok, %State{stream_to: self(), socket_id: socket_id} }

    assert validate Poison
  end

  test "handle subscription succeeded event" do
    state = %State{stream_to: self()}
    channel = "public-channel"
    event = %{
               "event" => "pusher_internal:subscription_succeeded",
               "channel" => channel,
               "data" => %{}
             }
    expect(Poison, :decode!, 1, event)
    expect(Poison, :decode, 1, {:ok, event["data"]})

    assert websocket_handle({:text, :event}, :conn_state, state) == { :ok, state }
    assert_receive %{channel: "public-channel",
                     event: "pusher:subscription_succeeded",
                     data: %{}}

    assert validate Poison
  end

  test "handle other events with encoded data" do
    state = %State{stream_to: self()}
    channel = "public-channel"
    event = %{
               "event" => "message",
               "channel" => channel,
               "data" => %{ "etc" => "anything" }
            }
    expect(Poison, :decode!, 1, event)
    expect(Poison, :decode, 1, {:ok, event["data"]})

    assert websocket_handle({:text, :event}, :conn_state, state) == { :ok, state }
    assert_receive %{channel: "public-channel",
                     event: "message",
                     data: %{"etc" => "anything"}}

    assert validate Poison
  end

  test "handle other events with non encoded data" do
    state = %State{stream_to: self()}
    channel = "public-channel"
    event = %{
               "event" => "message",
               "channel" => channel,
               "data" => %{ "etc" => "anything" }
            }
    expect(Poison, :decode!, 1, event)
    expect(Poison, :decode, 1, {:error, :badarg})

    assert websocket_handle({:text, :event}, :conn_state, state) == { :ok, state }
    assert_receive %{channel: "public-channel",
                     event: "message",
                     data: %{"etc" => "anything"}}

    assert validate Poison
  end

  test "subscribe to a public channel" do
    expect(PusherEvent, :subscribe, 1, :event_subscribe_json)

    assert websocket_info({:subscribe, "channel"}, :conn_state, :state) ==
      {:reply, {:text, :event_subscribe_json}, :state}

    assert validate PusherEvent
  end

  test "subscribe to a private channel" do
    credential = %Credential{app_key: "key", secret: "secret"}
    expect(PusherEvent, :subscribe, [{["private-channel", "123", credential], :event_subscribe_json}])

    state = %State{socket_id: "123",
                   credential: credential}
    assert websocket_info({:subscribe, "private-channel"}, :conn_state, state) ==
      {:reply, {:text, :event_subscribe_json}, state}

    assert validate PusherEvent
  end

  test "subscribe to a presence channel" do
    credential = %Credential{app_key: "key", secret: "secret"}
    user = %User{id: "123", info: %{}}
    expect(PusherEvent, :subscribe, [{["presence-channel", "123", credential, user], :event_subscribe_json}])

    state = %State{socket_id: "123",
                   credential: credential}
    assert websocket_info({:subscribe, "presence-channel", user}, :conn_state, state) ==
      {:reply, {:text, :event_subscribe_json}, state}

    assert validate PusherEvent
  end

  test "unsubscribe from a channel" do
    expect(PusherEvent, :unsubscribe, 1, :event_unsubscribe_json)

    assert websocket_info({:unsubscribe, "channel"}, :conn_state, :state) ==
      {:reply, {:text, :event_unsubscribe_json}, :state}

    assert validate PusherEvent
  end

  test "trigger client event" do
    expect(PusherEvent, :client_event, 3, :client_event_json)

    assert websocket_info({:trigger_event, "client-event", %{}, "private-channel"}, :conn_state, :state) ==
      {:reply, {:text, :client_event_json}, :state}

    assert validate PusherEvent
  end

  test "terminating with error code 4001" do
    state = %State{}

    assert websocket_terminate({:remote, 4001, "Message"}, :conn_state, state) == :ok
  end

  test "terminating with error code 4007" do
    state = %State{}

    assert websocket_terminate({:remote, 4007, "Message"}, :conn_state, state) == :ok
  end

  test "terminating normally" do
    assert websocket_terminate({:normal, "Message"}, :conn_state, nil) == :ok
  end
end
