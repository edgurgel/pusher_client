defmodule PusherClient.PusherEvent do

  @doc """
  Return a JSON for a subscription request using the `channel` name as parameter
  """
  @spec subscribe(binary) :: binary
  def subscribe(channel) do
    JSEX.encode!([ event: "pusher:subscribe",
                   data: [
                     channel: channel
                   ]
                 ])
  end

  @doc """
  Return a JSON for a unsubscription request using the `channel` name as parameter
  """
  @spec unsubscribe(binary) :: binary
  def unsubscribe(channel) do
    JSEX.encode!([ event: "pusher:unsubscribe",
                   data: [
                     channel: channel
                   ]
                 ])
  end

end
