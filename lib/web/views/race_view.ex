defmodule Web.RaceView do
  use Web, :view

  alias Data.Stats
  alias Web.Endpoint
  alias Web.Router.Helpers, as: RouteHelpers

  def stat(%{starting_stats: stats}, field) do
    stats
    |> Stats.default()
    |> Map.get(field)
  end

  def render("index.json", %{races: races}) do
    %{
      collection: render_many(races, __MODULE__, "show.json"),
      links: [
        %{rel: "self", href: RouteHelpers.public_race_url(Endpoint, :index)},
        %{rel: "up", href: RouteHelpers.public_page_url(Endpoint, :index)}
      ]
    }
  end

  def render("show.json", %{race: race, extended: true}) do
    %{
      key: race.api_id,
      name: race.name,
      description: race.description,
      links: [
        %{rel: "self", href: RouteHelpers.public_race_url(Endpoint, :show, race.id)},
        %{rel: "up", href: RouteHelpers.public_race_url(Endpoint, :index)}
      ]
    }
  end

  def render("show.json", %{race: race}) do
    %{
      key: race.api_id,
      name: race.name,
      links: [
        %{rel: "self", href: RouteHelpers.public_race_url(Endpoint, :show, race.id)}
      ]
    }
  end
end
