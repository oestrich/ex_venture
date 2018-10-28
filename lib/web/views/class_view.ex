defmodule Web.ClassView do
  use Web, :view

  require Representer

  alias Web.Endpoint
  alias Web.Router.Helpers, as: RouteHelpers
  alias Web.SkillView

  def render("index.json", %{classes: classes}) do
    %{
      collection: render_many(classes, __MODULE__, "show.json"),
      links: [
        %{rel: "self", href: RouteHelpers.public_class_url(Endpoint, :index)},
        %{rel: "up", href: RouteHelpers.public_page_url(Endpoint, :index)}
      ]
    }
  end

  def render("index." <> extension, %{classes: classes}) when Representer.known_extension?(extension) do
    classes
    |> index()
    |> Representer.transform(extension)
  end

  def render("show." <> extension, %{class: class}) when Representer.known_extension?(extension) do
    up = %Representer.Link{rel: "up", href: RouteHelpers.public_class_url(Endpoint, :index)}

    class
    |> show()
    |> embed_skills(class)
    |> Representer.Item.add_link(up)
    |> Representer.transform(extension)
  end

  def render("class.json", %{class: class}) do
    %{
      key: class.api_id,
      name: class.name,
      description: class.description,
    }
  end

  defp show(class) do
    %Representer.Item{
      rel: "https://exventure.org/rels/class",
      href: RouteHelpers.public_class_url(Endpoint, :show, class.id),
      item: render("class.json", %{class: class}),
      links: [
        %Representer.Link{rel: "self", href: RouteHelpers.public_class_url(Endpoint, :show, class.id)},
      ],
    }
  end

  defp index(classes) do
    classes = Enum.map(classes, &show/1)

    %Representer.Collection{
      href: RouteHelpers.public_class_url(Endpoint, :index),
      name: "classes",
      items: classes,
      links: [
        %Representer.Link{rel: "self", href: RouteHelpers.public_class_url(Endpoint, :index)},
        %Representer.Link{rel: "up", href: RouteHelpers.public_page_url(Endpoint, :index)}
      ]
    }
  end

  defp embed_skills(item, class) do
    skills =
      class.class_skills
      |> Enum.map(& &1.skill)
      |> Enum.map(&SkillView.show/1)

    %{item | embedded: %{skills: skills}}
  end
end
