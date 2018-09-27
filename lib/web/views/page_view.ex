defmodule Web.PageView do
  use Web, :view

  alias Game.Config
  alias Web.Color
  alias Web.Endpoint
  alias Web.Room
  alias Web.Router.Helpers, as: RouteHelpers
  alias Web.TimeView

  def render("who.json", %{players: players}) do
    %{
      collection: render_many(players, __MODULE__, "player.json", as: :player),
      links: [
        %{rel: "self", href: RouteHelpers.public_page_url(Endpoint, :who)},
        %{rel: "up", href: RouteHelpers.public_page_url(Endpoint, :index)}
      ],
    }
  end

  def render("player.json", %{player: player}) do
    %{
      name: player.name,
    }
  end

  def render("who." <> extension, %{players: players}) when extension in ["hal", "siren"] do
    players
    |> index()
    |> Representer.transform(extension)
  end

  def render("index.json", _) do
    %{
      links: [
        %{rel: "self", href: RouteHelpers.public_page_url(Endpoint, :index)},
        %{
          rel: "https://exventure.org/rel/who",
          href: RouteHelpers.public_page_url(Endpoint, :who)
        },
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

  def render("index." <> extension, _) when extension in ["collection", "hal", "siren"] do
    Representer.transform(%Representer.Collection{
      href: RouteHelpers.public_page_url(Endpoint, :index),
      name: "root",
      links: [
        %Representer.Link{rel: "self", href: RouteHelpers.public_page_url(Endpoint, :index)},
        %Representer.Link{rel: "curies", href: "https://exventure.org/rels/{exventure}", title: "exventure", template: true},
        %Representer.Link{rel: "exventure:who", href: RouteHelpers.public_page_url(Endpoint, :who)},
        %Representer.Link{rel: "exventure:classes", href: RouteHelpers.public_class_url(Endpoint, :index)},
        %Representer.Link{rel: "exventure:skills", href: RouteHelpers.public_skill_url(Endpoint, :index)},
        %Representer.Link{rel: "exventure:races", href: RouteHelpers.public_race_url(Endpoint, :index)}
      ]
    }, extension)
  end

  defp show(player) do
    %Representer.Item{
      item: render("player.json", %{player: player}),
      links: [
        %Representer.Link{rel: "curies", href: "https://exventure.org/rels/{exventure}", title: "exventure", template: true}
      ],
    }
  end

  defp index(who) do
    who = Enum.map(who, &show/1)

    %Representer.Collection{
      name: "who",
      items: who,
      links: [
        %Representer.Link{rel: "self", href: RouteHelpers.public_page_url(Endpoint, :index)},
        %Representer.Link{rel: "up", href: RouteHelpers.public_page_url(Endpoint, :index)}
      ]
    }
  end

  def xml_escape(string) do
    string
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
  end
end
