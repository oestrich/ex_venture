defmodule Game.Format.ContextTest do
  use ExUnit.Case

  alias Game.Format.Context

  describe "assigning variables" do
    setup do
      %{context: %Context{}}
    end

    test "assign a new variable", %{context: context} do
      context = Context.assign(context, :variable, :value)

      assert context.assigns.variable == :value
    end

    test "replace a variable", %{context: context} do
      context = Context.assign(context, :variable, :value)
      context = Context.assign(context, :variable, :new_value)

      assert context.assigns.variable == :new_value
    end

    test "mass assign variables", %{context: context} do
      context = Context.assign(context, %{variable: :value})

      assert context.assigns.variable == :value
    end
  end
end
