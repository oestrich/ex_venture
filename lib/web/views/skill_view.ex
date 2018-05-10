defmodule Web.SkillView do
  use Web, :view

  alias Web.Endpoint
  alias Web.Router.Helpers, as: RouteHelpers
  alias Web.SharedView

  def render("index.json", %{skills: skills, pagination: pagination}) do
    pagination_links =
      SharedView.page_links(pagination, RouteHelpers.public_skill_url(Endpoint, :index))

    %{
      collection: render_many(skills, __MODULE__, "show.json"),
      links:
        [
          %{rel: "self", href: RouteHelpers.public_skill_url(Endpoint, :index)},
          %{rel: "up", href: RouteHelpers.public_page_url(Endpoint, :index)}
        ] ++ pagination_links
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
        %{rel: "up", href: RouteHelpers.public_skill_url(Endpoint, :index)}
      ]
    }
  end

  def render("show.json", %{skill: skill, class: true}) do
    %{
      key: skill.api_id,
      level: skill.level,
      name: skill.name,
      links: [
        %{rel: "self", href: RouteHelpers.public_skill_url(Endpoint, :show, skill.id)}
      ]
    }
  end

  def render("show.json", %{skill: skill}) do
    %{
      key: skill.api_id,
      level: skill.level,
      name: skill.name,
      links: [
        %{rel: "self", href: RouteHelpers.public_skill_url(Endpoint, :show, skill.id)}
      ]
    }
  end
end
