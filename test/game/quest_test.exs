defmodule Game.QuestTest do
  use ExUnit.Case

  alias Data.QuestProgress
  alias Data.QuestStep
  alias Game.Quest

  describe "current step progress" do
    test "item/collect - no progress on a step yet" do
      step = %QuestStep{type: "item/collect"}
      progress = %QuestProgress{progress: %{}}
      assert Quest.current_step_progress(step, progress) == 0
    end

    test "item/collect - progress started" do
      step = %QuestStep{id: 1, type: "item/collect"}
      progress = %QuestProgress{progress: %{step.id => 3}}
      assert Quest.current_step_progress(step, progress) == 3
    end

    test "npc/kill - no progress on a step yet" do
      step = %QuestStep{type: "npc/kill"}
      progress = %QuestProgress{progress: %{}}
      assert Quest.current_step_progress(step, progress) == 0
    end

    test "npc/kill - progress started" do
      step = %QuestStep{id: 1, type: "npc/kill"}
      progress = %QuestProgress{progress: %{step.id => 3}}
      assert Quest.current_step_progress(step, progress) == 3
    end
  end
end
