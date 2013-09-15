# PusherClient [![Build Status](https://travis-ci.org/edgurgel/pusher-client.png?branch=master)](https://travis-ci.org/edgurgel/pusher-client)

Websocket client to Pusher service

## Usage

```iex
iex> {:ok, pid} = PusherClient.connect('ws://localhost:8080/app/app_key')
{:ok, #PID<0.134.0>}
iex> PusherClient.subscribe(pid, "channel")
:ok
```

Now, describe a event handler to receive events from this connection:

```elixir
defmodule EventHandler do
  use GenEvent.Behaviour

  def init(_), do: { :ok, nil }

  def handle_event(event, nil) do
    IO.inspect event, raw: true
    { :ok, nil }
  end
end
```

The `EventHandler` just print the received event. Now we add the handler and trigger an event:

```iex
iex> PusherClient.add_handler!(pid, PusherClient.EventHandler)
:ok
{"channel", "message", [{"text", "Hello!"}]}
```

That's it!

You can disconnect too:

```iex
iex> PusherClient.disconnect(pid)
:shutdown_ok
iex> 17:47:33.520 [info] Terminated: {:normal, "Normal shutdown"}
```

## TODO

* Support privat and presence channels;
* Add supervisors?
* Add tests to PusherClient module;
