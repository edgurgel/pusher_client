# PusherClient [![Build Status](https://travis-ci.org/edgurgel/pusher_client.png?branch=master)](https://travis-ci.org/edgurgel/pusher_client)

Websocket client to Pusher service

## Usage

```iex
iex> {:ok, pid} = PusherClient.connect!('ws://localhost:8080/app/app_key')
{:ok, #PID<0.134.0>}
iex> PusherClient.subscribe!(pid, "channel")
:ok
```

Now, describe a event handler to receive events from this connection:

```elixir
defmodule EventHandler do
  use GenEvent.Behaviour

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
iex> info = PusherClient.client_info(pid)
PusherClient.ClientInfo[gen_event_pid: #PID<0.130.0>, ws_pid: #PID<0.132.0>]
iex> :gen_event.add_handler(info.gen_event_pid, PusherClient.EventHandler, nil)
:ok
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
* Add tests to PusherClient module;
