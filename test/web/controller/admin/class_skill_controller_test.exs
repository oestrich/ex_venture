defmodule Web.Controller.ClassSkillControllerTest do
  use Web.AuthConnCase

  alias Web.Class

  setup do
    %{class: create_class(), skill: create_skill()}
  end

  test "add a skill to a class", %{conn: conn, class: class, skill: skill} do
    conn = post conn, class_skill_path(conn, :create, class.id), class_skill: %{skill_id: skill.id}
    assert html_response(conn, 302)
  end

  test "delete a skill from a class", %{conn: conn, class: class, skill: skill} do
    {:ok, class_skill} = Class.add_skill(class, skill.id)

    conn = delete conn, class_skill_path(conn, :delete, class_skill.id)
    assert html_response(conn, 302)
  end
end
