defmodule PusherClient do
  @moduledoc """
  Websocket Handler based on the Pusher Protocol: http://pusher.com/docs/pusher_protocol
  """
  require Logger
  alias PusherClient.PusherEvent

  @protocol 7

  defmodule Credential do
    defstruct app_key: "app_key", secret: "secret"
  end

  defmodule State do
    defstruct stream_to: nil, socket_id: nil, credential: %Credential{}
  end

  def start_link(url, app_key, secret, options \\ [])
  def start_link(url, app_key, secret, options) when is_list(url) do
    url = build_url(url, app_key)
    :websocket_client.start_link(url, __MODULE__, [app_key, secret, options])
  end
  def start_link(url, app_key, secret, options) when is_binary(url) do
    start_link(url |> to_char_list, app_key, secret, options)
  end

  defp build_url(url, app_key) do
    query = "?" <> URI.encode_query(%{protocol: @protocol})
    url ++ '/app/' ++ to_char_list(app_key) ++ to_char_list(query)
  end

  def subscribe!(pid, channel), do: send(pid, {:subscribe, channel})

  def unsubscribe!(pid, channel), do: send(pid, {:unsubscribe, channel})

  def disconnect!(pid), do: send(pid, :stop)

  @doc false
  def init([app_key, secret, options], _conn_state) do
    stream_to = Keyword.get(options, :stream_to, nil)
    credential = %Credential{app_key: app_key, secret: secret}
    { :ok, %State{stream_to: stream_to, credential: credential} }
  end

  @doc false
  def websocket_handle({ :text, event }, _conn_state, state) do
    event = JSEX.decode!(event)
    handle_event(event["event"], event, state)
  end

  @doc false
  def websocket_info({ :subscribe, channel = "private-" <> _ }, _conn_state, state) do
    event = PusherEvent.subscribe(channel, state.socket_id, state.credential)
    { :reply, { :text, event }, state }
  end
  def websocket_info({ :subscribe, channel }, _conn_state, state) do
    event = PusherEvent.subscribe(channel)
    { :reply, { :text, event }, state }
  end
  def websocket_info({ :unsubscribe, channel }, _conn_state, state) do
    event = PusherEvent.unsubscribe(channel)
    { :reply, { :text, event }, state }
  end
  def websocket_info(:stop, _conn_state, _state) do
    { :close, "Normal shutdown", nil }
  end
  def websocket_info(info, _conn_state, state) do
    Logger.info "info: #{inspect info}"
    { :ok, state }
  end

  @doc false
  def websocket_terminate({_close, 4001, _message} = reason, _conn_state, state) do
    Logger.error "Wrong app_key"
    do_websocket_terminate(reason, state)
  end
  def websocket_terminate({_close, 4007, _message} = reason, _conn_state, state) do
    Logger.error "Pusher server does not support current protocol #{@protocol}"
    do_websocket_terminate(reason, state)
  end
  def websocket_terminate({_close, code, payload } = reason, _conn_state, state) do
    Logger.info "Websocket close with code #{code} and payload '#{payload}'."
    do_websocket_terminate(reason, state)
  end
  def websocket_terminate({:normal, _message}, _conn_state, nil), do: :ok
  def websocket_terminate(reason, _conn_state, state) do
    do_websocket_terminate(reason, state)
  end
  def do_websocket_terminate(_reason, _state), do: :ok

  @doc false
  defp handle_event(event_name = "pusher:connection_established", event, state) do
    socket_id = event["data"]["socket_id"]
    notify(state.stream_to, event, event_name)
    Logger.info "Connection established on socket id: #{socket_id}"
    { :ok, %{state | socket_id: socket_id} }
  end
  defp handle_event("pusher_internal:subscription_succeeded", event, state) do
    notify(state.stream_to, event, "pusher:subscription_succeeded")
    { :ok, state }
  end
  defp handle_event(event_name, event, state) do
    notify(state.stream_to, event, event_name)
    { :ok, state }
  end

  defp notify(nil, _, _), do: :ok
  defp notify(stream_to, event, name) do
    send stream_to, %{ event: name, channel: event["channel"], data: event["data"] }
  end
end
