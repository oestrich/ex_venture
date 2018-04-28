defmodule Web.SkillView do
  use Web, :view

  alias Web.Endpoint
  alias Web.Router.Helpers, as: RouteHelpers

  def render("index.json", %{skills: skills}) do
    %{
      collection: render_many(skills, __MODULE__, "show.json"),
      links: [
        %{rel: "self", href: RouteHelpers.public_skill_url(Endpoint, :index)}
      ],
    }
  end

  def render("show.json", %{skill: skill, extended: true}) do
    %{
      key: skill.api_id,
      level: skill.level,
      name: skill.name,
      description: skill.description,
      command: skill.command,
      points: skill.points,
      links: [
        %{rel: "self", href: RouteHelpers.public_skill_url(Endpoint, :show, skill.id)},
        %{rel: "up", href: RouteHelpers.public_skill_url(Endpoint, :index)},
      ]
    }
  end

  def render("show.json", %{skill: skill, class: true}) do
    %{
      key: skill.api_id,
      level: skill.level,
      name: skill.name,
      links: [
        %{rel: "self", href: RouteHelpers.public_skill_url(Endpoint, :show, skill.id)},
      ]
    }
  end

  def render("show.json", %{skill: skill}) do
    %{
      key: skill.api_id,
      level: skill.level,
      name: skill.name,
      links: [
        %{rel: "self", href: RouteHelpers.public_skill_url(Endpoint, :show, skill.id)},
      ]
    }
  end
end
