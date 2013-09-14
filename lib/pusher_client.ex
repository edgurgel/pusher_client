defmodule PusherClient do
  use GenServer.Behaviour
  @doc """
  Connect to a websocket `url`
  """
  def connect(url) do
    :gen_server.start_link(PusherClient, [url], [])
  end

  @doc """
  Subscribe to `channel`
  """
  def subscribe(pid, channel) do
    :gen_server.call(pid, { :subscribe, channel })
  end

  @doc """
  Unsubscribe from`channel`
  """
  def unsubscribe(pid, channel) do
    :gen_server.call(pid, { :unsubscribe, channel })
  end

  @doc false
  def init([url]) do
    :websocket_client.start_link(url, PusherClient.Handler, [])
  end

  @doc false
  def handle_call({ :subscribe, channel }, _from, pid) do
    pid <- { :subscribe, channel }
    { :reply, :ok, pid }
  end
  @doc false
  def handle_call({ :unsubscribe, channel }, _from, pid) do
    pid <- { :unsubscribe, channel }
    { :reply, :ok, pid }
  end

end
