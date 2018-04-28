defmodule Web.ClassView do
  use Web, :view

  alias Web.Endpoint
  alias Web.Router.Helpers, as: RouteHelpers
  alias Web.SkillView

  def render("index.json", %{classes: classes}) do
    %{
      collection: render_many(classes, __MODULE__, "show.json"),
      links: [
        %{rel: "self", href: RouteHelpers.public_class_url(Endpoint, :index)},
        %{rel: "up", href: RouteHelpers.public_page_url(Endpoint, :index)}
      ],
    }
  end

  def render("show.json", %{class: class, extended: true}) do
    skills = Enum.map(class.class_skills, &(&1.skill))

    %{
      key: class.api_id,
      name: class.name,
      description: class.description,
      skills: render_many(skills, SkillView, "show.json", %{class: true}),
      links: [
        %{rel: "self", href: RouteHelpers.public_class_url(Endpoint, :show, class.id)},
        %{rel: "up", href: RouteHelpers.public_class_url(Endpoint, :index)},
      ]
    }
  end

  def render("show.json", %{class: class}) do
    %{
      key: class.api_id,
      name: class.name,
      description: class.description,
      links: [
        %{rel: "self", href: RouteHelpers.public_class_url(Endpoint, :show, class.id)},
      ]
    }
  end
end
