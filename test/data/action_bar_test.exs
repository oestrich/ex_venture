defmodule Data.ActionBarTest do
  use ExUnit.Case

  alias Data.ActionBar

  describe "adding a new action" do
    setup do
      save = %{actions: []}

      %{save: save}
    end

    test "less than 10 adds a new action", %{save: save} do
      action = %ActionBar.SkillAction{id: 1}

      save = ActionBar.maybe_add_action(save, action)

      assert length(save.actions) == 1
    end

    test "appends the action to the end", %{save: save} do
      action = %ActionBar.SkillAction{id: 1}

      save = %{save | actions: [%ActionBar.CommandAction{}]}
      save = ActionBar.maybe_add_action(save, action)

      assert [%ActionBar.CommandAction{} | _] = save.actions
    end

    test "does not add actions when the action bar is full", %{save: save} do
      action = %ActionBar.SkillAction{id: 1}

      actions = Enum.map(1..10, fn _ ->
        %ActionBar.CommandAction{}
      end)

      save = %{save | actions: actions}
      save = ActionBar.maybe_add_action(save, action)

      assert length(save.actions) == 10
    end
  end
end
