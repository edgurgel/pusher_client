# PusherClient [![Build Status](https://travis-ci.org/edgurgel/pusher_client.png?branch=master)](https://travis-ci.org/edgurgel/pusher_client)

Websocket client to Pusher service

## Usage

```iex
iex> {:ok, pid} = PusherClient.start_link("ws://localhost:8080", "app_key", "secret", stream_to: self)
{:ok, #PID<0.134.0>}
iex> PusherClient.subscribe!(pid, "channel")
:ok
```

```iex
# self will receive messages like this:
%{channel: nil,
  data: %{"activity_timeout" => 120,
    "socket_id" => "b388664a-3278-11e4-90df-7831c1bf9520"},
  event: "pusher:connection_established"}

%{channel: "channel", data: %{}, event: "pusher:subscription_succeeded"}
```

That's it!

You can disconnect too:

```iex
iex> PusherClient.disconnect!(pid)
:shutdown_ok
iex> 17:47:33.520 [info] Terminated: {:normal, "Normal shutdown"}
```

## TODO

* Support private and presence channels;
* Add supervisors?
