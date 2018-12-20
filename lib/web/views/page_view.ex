defmodule Web.PageView do
  use Web, :view

  require Representer

  alias Game.Config
  alias Web.Color
  alias Web.Endpoint
  alias Web.Room
  alias Web.TimeView
  alias Web.Router.Helpers, as: RouteHelpers

  def render("manifest.json", _assigns) do
    %{
      "name" => Config.game_name(),
      "short_name" => Config.game_short_name(),
      "display" => "fullscreen",
      "orientation" => "portrait-primary",
      "theme_color" => Config.color_home_header(),
      "background_color" => Config.color_home_header()
    }
  end

  def render("index." <> extension, _) when Representer.known_extension?(extension) do
    Representer.transform(
      %Representer.Collection{
        href: RouteHelpers.public_page_url(Endpoint, :index),
        name: "root",
        links: [
          %Representer.Link{rel: "self", href: RouteHelpers.public_page_url(Endpoint, :index)},
          %Representer.Link{
            rel: "curies",
            href: "https://exventure.org/rels/{exventure}",
            title: "exventure",
            template: true
          },
          %Representer.Link{
            rel: "exventure:who",
            href: RouteHelpers.public_who_url(Endpoint, :index)
          },
          %Representer.Link{
            rel: "exventure:classes",
            href: RouteHelpers.public_class_url(Endpoint, :index)
          },
          %Representer.Link{
            rel: "exventure:skills",
            href: RouteHelpers.public_skill_url(Endpoint, :index)
          },
          %Representer.Link{
            rel: "exventure:races",
            href: RouteHelpers.public_race_url(Endpoint, :index)
          }
        ]
      },
      extension
    )
  end

  def xml_escape(string) do
    string
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
  end
end
