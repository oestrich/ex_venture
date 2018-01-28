defmodule Web.Admin.SkillControllerTest do
  use Web.AuthConnCase

  test "create a skill", %{conn: conn} do
    params = %{
      name: "Slash",
      command: "slash",
      description: "Slash at the target",
      level: "1",
      user_text: "You slash at your {target}",
      usee_text: "You are slashed at by {who}",
      points: 3,
      effects: "[]",
    }

    conn = post conn, skill_path(conn, :create), skill: params
    assert html_response(conn, 302)
  end

  test "update a skill", %{conn: conn} do
    skill = create_skill()

    conn = put conn, skill_path(conn, :update, skill.id), skill: %{name: "Dodge"}
    assert html_response(conn, 302)
  end
end
