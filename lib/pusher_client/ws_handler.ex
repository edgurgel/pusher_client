defmodule PusherClient.WSHandler do
  @moduledoc """
  Websocket Handler based on the Pusher Protocol: http://pusher.com/docs/pusher_protocol
  """
  require Lager
  alias PusherClient.PusherEvent

  @protocol 7

  def protocol, do: @protocol

  defrecord WSHandlerInfo, gen_event_pid: nil, socket_id: nil do
    record_type gen_event_pid: pid, socket_id: nil | binary
  end

  @doc false
  def init(gen_event_pid, _conn_state) do
    { :ok, WSHandlerInfo.new(gen_event_pid: gen_event_pid) }
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
  def websocket_info(:stop, _conn_state, _state) do
    { :close, "Normal shutdown", nil }
  end
  def websocket_info(info, _conn_state, state) do
    Lager.info "info: #{inspect info}"
    { :ok, state }
  end

  @doc false
  def websocket_terminate({_close, 4001, _message}, _conn_state, _state) do
    Lager.error "Wrong app_key"
    :ok
  end
  def websocket_terminate({_close, 4007, _message}, _conn_state, _state) do
    Lager.error "Pusher server does not support current protocol #{@protocol}"
    :ok
  end
  def websocket_terminate({_close, code, payload }, _conn_state, _state) do
    Lager.info "Websocket close with code #{code} and payload '#{payload}'."
    :ok
  end
  def websocket_terminate(reason, _conn_state, _state) do
    Lager.info "Terminated: #{inspect reason}"
    :ok
  end

  @doc false
  defp handle_event("pusher:connection_established", event, state) do
    socket_id = event["data"]["socket_id"]
    Lager.info "Connection established on socket id: #{socket_id}"
    { :ok, state.update(socket_id: socket_id) }
  end
  defp handle_event("pusher_internal:subscription_succeeded", event, WSHandlerInfo[gen_event_pid: gen_event_pid] = state) do
    notify(gen_event_pid, event, "pusher:subscription_succeeded")
    { :ok, state }
  end
  defp handle_event(event_name, event, WSHandlerInfo[gen_event_pid: gen_event_pid] = state) do
    notify(gen_event_pid, event, event_name)
    { :ok, state }
  end

  defp notify(gen_event_pid, event, name) do
    :gen_event.notify(gen_event_pid, { event["channel"], name, event["data"] })
  end
end
