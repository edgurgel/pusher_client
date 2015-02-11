defmodule PusherClient.EventTest do
  use ExUnit.Case
  alias PusherClient.Credential
  alias PusherClient.User
  import PusherClient.PusherEvent
  import :meck

  setup do
    new JSX
    on_exit fn -> unload end
    :ok
  end

  test "subscribe to public channel" do
    event = %{ event: "pusher:subscribe",
               data: %{ channel: "channel" } }
    expect(JSX, :encode!, [{[event], :ok}])

    assert subscribe("channel") == :ok

    assert validate(JSX)
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
    expect(JSX, :encode!, [{[event], :ok}])

    assert subscribe("private-foobar", "1234.1234", credential) == :ok

    assert validate(JSX)
  end

  # Using https://pusher.com/docs/auth_signatures as example
  test "subscribe to presence channel" do
    user = %User{id: 10, info: %{name: "Mr. Pusher"}}
    channel_data = "{\"user_id\":10,\"user_info\":{\"name\":\"Mr. Pusher\"}}"
    key = "278d425bdf160c739803"
    secret = "7ad3773142a6692b25b8"
    auth = "278d425bdf160c739803:afaed3695da2ffd16931f457e338e6c9f2921fa133ce7dac49f529792be6304c"
    credential = %Credential{app_key: key, secret: secret}
    event = %{event: "pusher:subscribe",
              data: %{channel: "presence-foobar",
                      auth: auth,
                      channel_data: channel_data}}
    expect(JSX, :encode!,
      [{[event], :ok},
       {[%{user_id: 10, user_info: %{name: "Mr. Pusher"}}], channel_data}])

    assert subscribe("presence-foobar", "1234.1234", credential, user) == :ok

    assert validate(JSX)
  end

  test "unsubscribe to a channel" do
    event = %{ event: "pusher:unsubscribe",
               data: %{ channel: "channel" } }
    expect(JSX, :encode!, [{[event], :ok}])

    assert unsubscribe("channel") == :ok

    assert validate(JSX)
  end
end
