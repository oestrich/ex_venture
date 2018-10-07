defmodule Web.SkillView do
  use Web, :view

  require Representer

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

  def render("index." <> extension, %{skills: skills, pagination: pagination}) when Representer.known_extension?(extension) do
    skills
    |> index(pagination)
    |> Representer.transform(extension)
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

  def render("show." <> extension, %{skill: skill}) when Representer.known_extension?(extension) do
    skill
    |> show()
    |> Representer.transform(extension)
  end

  def show(skill) do
    %Representer.Item{
      href: RouteHelpers.public_skill_url(Endpoint, :show, skill.id),
      rel: "https://exventure.org/rels/skill",
      item: Map.delete(render("show.json", %{skill: skill}), :links),
      links: [
        %Representer.Link{rel: "self", href: RouteHelpers.public_skill_url(Endpoint, :show, skill.id)}
      ]
    }
  end

  defp index(skills, pagination) do
    skills = Enum.map(skills, &show/1)

    %Representer.Collection{
      name: "skills",
      items: skills,
      pagination: %Representer.Pagination{
        base_url: RouteHelpers.public_skill_url(Endpoint, :index),
        current_page: pagination.current,
        total_pages: pagination.total,
        total_count: pagination.total_count,
      },
      links: [
        %Representer.Link{rel: "self", href: RouteHelpers.public_skill_url(Endpoint, :index)},
        %Representer.Link{rel: "up", href: RouteHelpers.public_page_url(Endpoint, :index)}
      ]
    }
  end
end
