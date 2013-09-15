defmodule PusherClient.EventHandler do
  use GenEvent.Behaviour
  @moduledoc """
  Dummy event handler for testing purposes
  """

  @doc false
  def init(_), do: { :ok, nil }

  @doc false
  def handle_event(event, nil) do
    IO.inspect event, raw: true
    { :ok, nil }
  end
end
