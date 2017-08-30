defmodule Web.Admin.SkillControllerTest do
  use Web.AuthConnCase

  setup do
    class = create_class()
    %{class: class}
  end

  test "create a skill", %{conn: conn, class: class} do
    params = %{
      name: "Slash",
      command: "slash",
      description: "Slash at the target",
      user_text: "You slash at your {target}",
      usee_text: "You are slashed at by {who}",
      points: 3,
      effects: "[]",
    }

    conn = post conn, class_skill_path(conn, :create, class.id), skill: params
    assert html_response(conn, 302)
  end

  test "update a skill", %{conn: conn, class: class} do
    skill = create_skill(class)

    conn = put conn, skill_path(conn, :update, skill.id), skill: %{name: "Dodge"}
    assert html_response(conn, 302)
  end
end
