defmodule Web.WhoView do
  use Web, :view

  require Representer

  alias Web.Endpoint
  alias Web.Router.Helpers, as: RouteHelpers

  def render("index." <> extension, %{players: players}) when Representer.known_extension?(extension) do
    players
    |> index()
    |> Representer.transform(extension)
  end

  def render("player.json", %{player: player}) do
    %{
      name: player.name,
    }
  end

  defp show(player) do
    %Representer.Item{
      item: render("player.json", %{player: player}),
      links: [],
    }
  end

  defp index(players) do
    players = Enum.map(players, &show/1)

    %Representer.Collection{
      name: "players",
      items: players,
      links: [
        %Representer.Link{rel: "self", href: RouteHelpers.public_page_url(Endpoint, :index)},
        %Representer.Link{rel: "up", href: RouteHelpers.public_page_url(Endpoint, :index)}
      ]
    }
  end
end
