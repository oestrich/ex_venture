defmodule Kantele.Character.CommandView do
  use Kalevala.Character.View

  alias Kalevala.Character.Conn.EventText

  def render("prompt", %{character: character}) do
    %{vitals: vitals} = character.meta

    %EventText{
      topic: "Character.Prompt",
      data: vitals,
      text: [
        "[",
        ~i({hp}#{vitals.health_points}/#{vitals.max_health_points}hp{/hp} ),
        ~i({sp}#{vitals.skill_points}/#{vitals.max_skill_points}sp{/sp} ),
        ~i({ep}#{vitals.endurance_points}/#{vitals.max_endurance_points}ep{/ep}),
        "] > "
      ]
    }
  end

  def render("unknown", _assigns) do
    "What?\n"
  end
end
