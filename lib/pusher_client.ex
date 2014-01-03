defmodule PusherClient do
  use GenServer.Behaviour

  defrecord ClientInfo, gen_event_pid: nil, ws_pid: nil do
    record_type gen_event_pid: pid, ws_pid: nil
  end

  @doc """
  Connect to a websocket `url`
  """
  def connect!(url) do
    { :ok, gen_event_pid } = :gen_event.start_link
    { :ok, pid } = :gen_server.start_link(PusherClient, [url, gen_event_pid], [])
    { :ok, pid }
  end

  @doc """
  Disconnect from an open websocket connection passing.
  """
  def disconnect!(pid) do
    :gen_server.call(pid, :stop)
  end

  @doc """
  Returns actual client information with gen_event_pid and ws_pid
  GenEvent stuff (add_handler, delete_handler, call, ...) can use gen_event_pid
  """
  def client_info(pid), do: :gen_server.call(pid, :client_info)

  @doc """
  Subscribe to `channel`
  """
  def subscribe!(pid, channel) do
    :gen_server.call(pid, { :subscribe, channel })
  end

  @doc """
  Unsubscribe from`channel`
  """
  def unsubscribe!(pid, channel) do
    :gen_server.call(pid, { :unsubscribe, channel })
  end

  @doc false
  def init([url, gen_event_pid]) do
    { :ok, ws_pid } = :websocket_client.start_link(url, PusherClient.WSHandler, gen_event_pid)
    { :ok, ClientInfo.new(ws_pid: ws_pid, gen_event_pid: gen_event_pid) }
  end

  @doc false
  def handle_call(:client_info, _from, state), do: { :reply, state, state }
  def handle_call({ :subscribe, channel }, _from, ClientInfo[ws_pid: ws_pid] = state) do
    ws_pid <- { :subscribe, channel }
    { :reply, :ok, state }
  end
  def handle_call({ :unsubscribe, channel }, _from, ClientInfo[ws_pid: ws_pid] = state) do
    ws_pid <- { :unsubscribe, channel }
    { :reply, :ok, state }
  end
  def handle_call(:stop, _from, ClientInfo[ws_pid: ws_pid] = _state) do
    ws_pid <- :stop
    { :stop, :normal, :shutdown_ok, nil}
  end
end
