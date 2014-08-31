defmodule PusherClient.EventTest do
  use ExUnit.Case
  alias PusherClient.Credential
  import PusherClient.PusherEvent
  import :meck

  setup do
    new JSEX
    on_exit fn -> unload end
    :ok
  end

  test "subscribe to public channel" do
    event = %{ event: "pusher:subscribe",
               data: %{ channel: "channel" } }
    expect(JSEX, :encode!, [{[event], :ok}])

    assert subscribe("channel") == :ok

    assert validate(JSEX)
  end

  # Using https://pusher.com/docs/auth_signatures as example
  test "subscribe to private channel" do
    key = "278d425bdf160c739803"
    secret = "7ad3773142a6692b25b8"
    auth = "278d425bdf160c739803:58df8b0c36d6982b82c3ecf6b4662e34fe8c25bba48f5369f135bf843651c3a4"
    credential = %Credential{app_key: key, secret: secret}
    event = %{event: "pusher:subscribe",
              data: %{channel: "private-foobar",
                      auth: auth}}
    expect(JSEX, :encode!, [{[event], :ok}])

    assert subscribe("private-foobar", "1234.1234", credential) == :ok

    assert validate(JSEX)
  end

  test "unsubscribe to a channel" do
    event = %{ event: "pusher:unsubscribe",
               data: %{ channel: "channel" } }
    expect(JSEX, :encode!, [{[event], :ok}])

    assert unsubscribe("channel") == :ok

    assert validate(JSEX)
  end
end
