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

  describe "assigning a render many" do
    setup do
      %{context: %Context{}}
    end

    test "assign a new list of values and the render function", %{context: context} do
      context = Context.assign_many(context, :variable, [:value], fn value -> to_string(value) end)

      assert {[:value], _, []} = context.many_assigns.variable
    end
  end
end
