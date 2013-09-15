defmodule PusherClient do
  use GenServer.Behaviour

  defrecord ClientInfo, gen_event_pid: nil, ws_pid: nil do
    record_type gen_event_pid: pid, ws_pid: nil
  end

  @doc """
  Connect to a websocket `url`
  """
  def connect!(url) do
    {:ok, gen_event_pid } = :gen_event.start_link
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
  Add an event handler, see `gen_event` documentation.
  """
  def add_handler!(pid, handler), do: :gen_server.call(pid, { :add_handler, handler })

  @doc """
  Delete event handler, see `gen_event` documentation.
  """
  def delete_handler!(pid, handler), do: :gen_server.call(pid, { :delete_handler, handler })

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
  def handle_call({ :subscribe, channel }, _from, ClientInfo[ws_pid: ws_pid] = state) do
    ws_pid <- { :subscribe, channel }
    { :reply, :ok, state }
  end
  def handle_call({ :unsubscribe, channel }, _from, ClientInfo[ws_pid: ws_pid] = state) do
    ws_pid <- { :unsubscribe, channel }
    { :reply, :ok, state }
  end
  def handle_call({ :add_handler, handler }, _from, ClientInfo[gen_event_pid: gen_event_pid] = state) do
    :gen_event.add_handler(gen_event_pid, handler, nil)
    { :reply, :ok, state }
  end
  def handle_call({ :delete_handler, handler }, _from, ClientInfo[gen_event_pid: gen_event_pid] = state) do
    :gen_event.delete_handler(gen_event_pid, handler, nil)
    { :reply, :ok, state }
  end
  def handle_call(:stop, _from, ClientInfo[ws_pid: ws_pid] = _state) do
    ws_pid <- :stop
    { :stop, :normal, :shutdown_ok, nil}
  end


end
