defmodule PusherClient do
  @moduledoc """
  Websocket Handler based on the Pusher Protocol: http://pusher.com/docs/pusher_protocol
  """
  require Lager
  alias PusherClient.PusherEvent

  @protocol 7

  defmodule State do
    defstruct gen_event_pid: nil, socket_id: nil
  end

  def start_link(url) when is_list(url) do
    query = "?" <> URI.encode_query(%{protocol: @protocol})
    :websocket_client.start_link(url ++ to_char_list(query), __MODULE__, [])
  end
  def start_link(url) when is_binary(url) do
    start_link(url |> to_char_list)
  end

  def subscribe!(pid, channel), do: send(pid, {:subscribe, channel})

  def unsubscribe!(pid, channel), do: send(pid, {:unsubscribe, channel})

  def add_handler(pid, module, args), do: send(pid, {:add_handler, module, args})

  def add_sup_handler(pid, module, args), do: send(pid, {:add_sup_handler, module, args})

  def disconnect!(pid), do: send(pid, :stop)

  @doc false
  def init(url, _conn_state) do
    { :ok, gen_event_pid } = :gen_event.start_link
    { :ok, %State{gen_event_pid: gen_event_pid} }
  end

  @doc false
  def websocket_handle({ :text, event }, _conn_state, state) do
    event = JSEX.decode!(event)
    handle_event(event["event"], event, state)
  end

  @doc false
  def websocket_info({ :subscribe, channel }, _conn_state, state) do
    event = PusherEvent.subscribe(channel)
    { :reply, { :text, event }, state }
  end
  def websocket_info({ :unsubscribe, channel }, _conn_state, state) do
    event = PusherEvent.unsubscribe(channel)
    { :reply, { :text, event }, state }
  end
  def websocket_info({ :add_handler, module, args}, _conn_state, %State{gen_event_pid: gen_event_pid} = state) do
    :gen_event.add_handler(gen_event_pid, module, args)
    { :ok, state}
  end
  def websocket_info({ :add_sup_handler, module, args}, _conn_state, %State{gen_event_pid: gen_event_pid} = state) do
    :gen_event.add_sup_handler(gen_event_pid, module, args)
    { :ok, state}
  end
  def websocket_info(:stop, _conn_state, _state) do
    { :close, "Normal shutdown", nil }
  end
  def websocket_info(info, _conn_state, state) do
    Lager.info "info: #{inspect info}"
    { :ok, state }
  end

  @doc false
  def websocket_terminate({_close, 4001, _message} = reason, _conn_state, state) do
    Lager.error "Wrong app_key"
    do_websocket_terminate(reason, state)
  end
  def websocket_terminate({_close, 4007, _message} = reason, _conn_state, state) do
    Lager.error "Pusher server does not support current protocol #{@protocol}"
    do_websocket_terminate(reason, state)
  end
  def websocket_terminate({_close, code, payload } = reason, _conn_state, state) do
    Lager.info "Websocket close with code #{code} and payload '#{payload}'."
    do_websocket_terminate(reason, state)
  end
  def websocket_terminate({:normal, _message}, _conn_state, nil), do: :ok
  def websocket_terminate(reason, _conn_state, state) do
    do_websocket_terminate(reason, state)
  end
  def do_websocket_terminate(reason, _state) do
    :ok
  end

  @doc false
  defp handle_event("pusher:connection_established", event, state) do
    socket_id = event["data"]["socket_id"]
    Lager.info "Connection established on socket id: #{socket_id}"
    { :ok, %{state | socket_id: socket_id} }
  end
  defp handle_event("pusher_internal:subscription_succeeded", event, %State{gen_event_pid: gen_event_pid} = state) do
    notify(gen_event_pid, event, "pusher:subscription_succeeded")
    { :ok, state }
  end
  defp handle_event(event_name, event, %State{gen_event_pid: gen_event_pid} = state) do
    notify(gen_event_pid, event, event_name)
    { :ok, state }
  end

  defp notify(gen_event_pid, event, name) do
    :gen_event.sync_notify(gen_event_pid, { event["channel"], name, event["data"] })
  end
end
