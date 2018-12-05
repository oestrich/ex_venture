defmodule Data.Events.ActionsTest do
  use ExUnit.Case

  alias Data.Events.Actions

  doctest Actions

  describe "parsing actions" do
    test "parsing delay" do
      {:ok, action} = Actions.parse(%{
        "type" => "commands/say",
        "delay" => 1
      })

      assert action.delay == 1
    end

    test "parsing bad delay" do
      {:ok, action} = Actions.parse(%{
        "type" => "commands/say",
        "delay" => nil
      })

      assert action.delay == 0
    end

    test "parsing options" do
      {:ok, action} = Actions.parse(%{
        "type" => "commands/say",
        "options" => %{
          "message" => "hello",
        },
      })

      assert action.options == %{message: "hello"}
    end
  end
end
