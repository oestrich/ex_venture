defmodule Data.ScriptTest do
  use Data.ModelCase
  doctest Data.Script
  doctest Data.Script.Line

  alias Data.Script
  alias Data.Script.Line

  describe "validate the script" do
    test "must include a start key" do
      script = [%Line{key: "start", message: "Hi"}]
      assert Script.valid_script?(script)

      script = [%Line{key: "end", message: "Hi"}]
      refute Script.valid_script?(script)
    end

    test "each key must be present" do
      script = [
        %Line{key: "start", message: "Hi", listeners: [%{phrase: "yes", key: "continue"}]},
        %Line{key: "continue", message: "Hi"},
      ]
      assert Script.valid_script?(script)

      script = [
        %Line{key: "start", message: "Hi", listeners: [%{phrase: "yes", key: "continue"}]},
      ]
      refute Script.valid_script?(script)
    end
  end
end
