defmodule PusherClient do
  use GenServer.Behaviour
  require Lager
  import PusherClient.WSHandler, only: [protocol: 0]

  defrecord ClientInfo, gen_event_pid: nil, ws_pid: nil do
    record_type gen_event_pid: pid, ws_pid: nil
  end

  @doc """
  Connect to a websocket `url`
  """
  def connect!(url) when is_list(url) do
    { :ok, gen_event_pid } = :gen_event.start_link
    query = "?" <> URI.encode_query(%{protocol: protocol})
    :gen_server.start(PusherClient, [url ++ to_char_list(query), gen_event_pid], [])
  end
  def connect!(url) when is_binary(url), do: connect!(url |> to_char_list)

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
    case :websocket_client.start_link(url, PusherClient.WSHandler, { self, gen_event_pid  }) do
      { :ok, ws_pid } ->
        { :ok, ClientInfo.new(ws_pid: ws_pid, gen_event_pid: gen_event_pid) }
      { :error, reason } -> { :stop, reason }
    end
  end

  @doc false
  def handle_call(:client_info, _from, state), do: { :reply, state, state }
  def handle_call({ :subscribe, channel }, _from, ClientInfo[ws_pid: ws_pid] = state) do
    send ws_pid, { :subscribe, channel }
    { :reply, :ok, state }
  end
  def handle_call({ :unsubscribe, channel }, _from, ClientInfo[ws_pid: ws_pid] = state) do
    send ws_pid, { :unsubscribe, channel }
    { :reply, :ok, state }
  end
  def handle_call(:stop, _from, ClientInfo[ws_pid: ws_pid] = _state) do
    Lager.info "Disconnecting"
    send ws_pid, :stop
    # Check this reply!
    { :stop, :normal, :ok, nil}
  end

  def handle_info({ :stop, reason }, _state) do
    { :stop, reason, nil }
  end

  def terminate(reason, _state) do
    Lager.info "Terminating, reason: #{inspect reason}"
    { :shutdown, reason }
  end
end
