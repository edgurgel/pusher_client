defmodule PusherClient.Handler do
  require Lager
  alias PusherClient.PusherEvent

  @doc false
  def init(_args, _conn_state), do: { :ok, nil }

  @doc false
  def websocket_handle({ :text, event }, _conn_state, state) do
    event = JSEX.decode!(event)
    handle_event(event["event"], event["data"], state)
  end

  @doc false
  def websocket_info({ :subscribe, channel }, _conn_state, socket_id) do
    event = PusherEvent.subscribe(channel)
    { :reply, { :text, event }, socket_id }
  end
  def websocket_info({ :unsubscribe, channel }, _conn_state, socket_id) do
    event = PusherEvent.unsubscribe(channel)
    { :reply, { :text, event }, socket_id }
  end
  def websocket_info(info, _conn_state, socket_id) do
    Lager.info "info: #{inspect info}"
    { :ok, socket_id }
  end

  @doc false
  def websocket_terminate({ :close, code, payload }, _conn_state, _state) do
    Lager.info "websocket close with code #{code} and payload #{payload}."
    :ok
  end
  def websocket_terminate(reason, _conn_state, _state) do
    Lager.info "Terminated: #{inspect reason}"
    :ok
  end

  @doc false
  defp handle_event("pusher:connection_established", data, _state) do
    socket_id = data["socket_id"]
    Lager.info "Connection established on socket id: #{socket_id}"
    { :ok, socket_id }
  end
  defp handle_event("pusher_internal:subscription_succeeded", data, state) do
    { :ok, state }
  end
end
