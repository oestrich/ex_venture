defmodule Game.InsightTest do
  use ExUnit.Case

  alias Game.Insight

  test "log bad commands" do
    # Clear out any commands from the rest of the test suite
    :sys.replace_state(Insight, fn (state) -> Map.put(state, :bad_commands, []) end)

    :ok = Insight.bad_command("unknown command")

    assert [{"unknown command", _}] = Insight.bad_commands()
  end
end
