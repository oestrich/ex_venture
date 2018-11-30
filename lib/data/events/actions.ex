defmodule Data.Events.Actions do
  @type options_mapping :: map()

  @callback type() :: String.t()

  @callback options :: options_mapping()

  def parse(module, actions) do
    IO.inspect module
    IO.inspect actions
  end
end
