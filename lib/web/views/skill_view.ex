defmodule Web.SkillView do
  use Web, :view

  require Representer

  alias Web.Endpoint
  alias Web.Router.Helpers, as: RouteHelpers
  alias Web.SharedView

  def render("index." <> extension, %{skills: skills, pagination: pagination}) when Representer.known_extension?(extension) do
    skills
    |> index(pagination)
    |> Representer.transform(extension)
  end

  def render("show." <> extension, %{skill: skill}) when Representer.known_extension?(extension) do
    skill
    |> show(extended: true)
    |> Representer.transform(extension)
  end

  def render("skill.json", %{skill: skill, extended: true}) do
    %{
      key: skill.api_id,
      level: skill.level,
      name: skill.name,
      description: skill.description,
      command: skill.command,
      points: skill.points,
    }
  end

  def render("skill.json", %{skill: skill}) do
    %{
      key: skill.api_id,
      level: skill.level,
      name: skill.name,
    }
  end

  def show(skill, opts \\ []) do
    %Representer.Item{
      href: RouteHelpers.public_skill_url(Endpoint, :show, skill.id),
      rel: "https://exventure.org/rels/skill",
      item: render("skill.json", %{skill: skill, extended: Keyword.get(opts, :extended, false)}),
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
