defmodule Web.RaceView do
  use Web, :view

  require Representer

  alias Data.Stats
  alias Web.Endpoint
  alias Web.Router.Helpers, as: RouteHelpers

  def stat(%{starting_stats: stats}, field) do
    stats
    |> Stats.default()
    |> Map.get(field)
  end

  def render("index." <> extension, %{races: races})
      when Representer.known_extension?(extension) do
    races
    |> index()
    |> Representer.transform(extension)
  end

  def render("show." <> extension, %{race: race}) when Representer.known_extension?(extension) do
    up = %Representer.Link{rel: "up", href: RouteHelpers.public_race_url(Endpoint, :index)}

    race
    |> show(extended: true)
    |> Representer.Item.add_link(up)
    |> Representer.transform(extension)
  end

  def render("race.json", %{race: race, extended: true}) do
    %{
      key: race.api_id,
      name: race.name,
      description: race.description,
      stats: %{
        health_points: stat(race, :health_points),
        max_health_points: stat(race, :health_points),
        skill_points: stat(race, :skill_points),
        max_skill_points: stat(race, :skill_points),
        endurance_points: stat(race, :endurance_points),
        max_endurance_points: stat(race, :max_endurance_points),
        strength: stat(race, :strength),
        agility: stat(race, :agility),
        intelligence: stat(race, :intelligence),
        awareness: stat(race, :awareness),
        vitality: stat(race, :vitality),
        willpower: stat(race, :willpower)
      }
    }
  end

  def render("race.json", %{race: race}) do
    %{
      key: race.api_id,
      name: race.name
    }
  end

  defp show(race, opts \\ []) do
    %Representer.Item{
      href: RouteHelpers.public_race_url(Endpoint, :show, race.id),
      rel: "https://exventure.org/rels/race",
      item: render("race.json", %{race: race, extended: Keyword.get(opts, :extended, false)}),
      links: [
        %Representer.Link{
          rel: "self",
          href: RouteHelpers.public_race_url(Endpoint, :show, race.id)
        }
      ]
    }
  end

  defp index(races) do
    races = Enum.map(races, &show/1)

    %Representer.Collection{
      href: RouteHelpers.public_race_url(Endpoint, :index),
      name: "races",
      items: races,
      links: [
        %Representer.Link{rel: "self", href: RouteHelpers.public_race_url(Endpoint, :index)},
        %Representer.Link{rel: "up", href: RouteHelpers.public_page_url(Endpoint, :index)}
      ]
    }
  end
end
