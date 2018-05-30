defmodule Web.PageView do
  use Web, :view

  alias Game.Config
  alias Web.Color
  alias Web.Endpoint
  alias Web.Room
  alias Web.Router.Helpers, as: RouteHelpers
  alias Web.TimeView

  def render("index.json", _) do
    %{
      links: [
        %{rel: "self", href: RouteHelpers.public_page_url(Endpoint, :index)},
        %{
          rel: "https://exventure.org/rel/classes",
          href: RouteHelpers.public_class_url(Endpoint, :index)
        },
        %{
          rel: "https://exventure.org/rel/skills",
          href: RouteHelpers.public_skill_url(Endpoint, :index)
        },
        %{
          rel: "https://exventure.org/rel/races",
          href: RouteHelpers.public_race_url(Endpoint, :index)
        }
      ]
    }
  end
end
