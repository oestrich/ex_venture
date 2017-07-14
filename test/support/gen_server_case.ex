defmodule GenServerCase do
  defmacro __using__(_opts) do
    quote do
      use ExUnit.Case
      import GenServerCase
    end
  end

  def wait_cast(pid) do
    _state = :sys.get_state(pid)
  end
end
