# PusherClient [![Build Status](https://travis-ci.org/edgurgel/pusher_client.png?branch=master)](https://travis-ci.org/edgurgel/pusher_client)

Websocket client to Pusher service

## Usage

```iex
iex> {:ok, pid} = PusherClient.start_link("ws://localhost:8080", "app_key", "secret")
{:ok, #PID<0.134.0>}
iex> PusherClient.subscribe!(pid, "channel")
:ok
```

Now, describe a event handler to receive events from this connection:

```elixir
defmodule EventHandler do
  use GenEvent

  def init(_), do: { :ok, nil }

  def handle_event(event, nil) do
    IO.inspect event, raw: true
    { :ok, event }
  end

  def handle_call(:last_event, event), do: {:ok, event, event}
end
```

The `EventHandler` just print the received event. Now we add the handler and trigger an event:

```iex
iex> PusherClient.add_handler(pid, EventHandler)
:ok
# After an event:
{"channel", "message", [{"text", "Hello!"}]}
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
