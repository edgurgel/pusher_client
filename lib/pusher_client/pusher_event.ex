defmodule PusherClient.PusherEvent do
  import JSEX, only: [encode!: 1]
  alias PusherClient.Credential

  @doc """
  Return a JSON for a subscription request using the `channel` name as parameter
  """
  @spec subscribe(binary) :: binary
  def subscribe(channel) do
    %{ event: "pusher:subscribe",
       data: %{ channel: channel } } |> encode!
  end

  @doc """
  Return a JSON for a subscription request using the private `channel`, `socket_id`
  and the credential
  """
  def subscribe(channel, socket_id, %Credential{secret: secret, app_key: app_key}) do
    to_sign = socket_id <> ":" <> channel
    auth = app_key <> ":" <> hmac256(secret, to_sign)
    %{ event: "pusher:subscribe",
       data: %{ channel: channel,
                auth: auth }
     } |> encode!
  end

  @doc """
  Return a JSON for a unsubscription request using the `channel` name as parameter
  """
  @spec unsubscribe(binary) :: binary
  def unsubscribe(channel) do
    %{ event: "pusher:unsubscribe",
       data: %{ channel: channel } } |> encode!
  end

  defp hmac256(app_secret, to_sign) do
    :crypto.hmac(:sha256, app_secret, to_sign)
    |> hexlify
    |> :string.to_lower
    |> List.to_string
  end

  defp hexlify(binary) do
    :lists.flatten(for b <- :erlang.binary_to_list(binary), do: :io_lib.format("~2.16.0B", [b]))
  end
end
