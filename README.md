# PusherClient

Websocket client to Pusher service

## Usage

```iex
iex> {:ok, pid} = PusherClient.connect('ws://localhost:8080/app/app_key')
{:ok, #PID<0.134.0>}
iex> PusherClient.subscribe(pid, "channel")
:ok
```

That's it for now!
