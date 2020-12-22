defmodule ExVenture.TestHelpers do
  @moduledoc """
  Test Helpers for creating database records
  """

  alias ExVenture.APIKeys
  alias ExVenture.Repo
  alias ExVenture.Rooms
  alias ExVenture.Users
  alias ExVenture.Zones

  def create_api_key(params \\ %{}), do: APIKeys.create(params)

  def create_user(params \\ %{}) do
    params =
      Map.merge(
        %{
          username: "user",
          email: "user@example.com",
          password: "password",
          password_confirmation: "password"
        },
        params
      )

    Users.create(params)
  end

  def create_admin(params \\ %{}) do
    {:ok, user} = create_user(params)

    user
    |> Ecto.Changeset.change(%{role: "admin"})
    |> Repo.update()
  end

  def create_room(zone, params \\ %{}) do
    params =
      Map.merge(
        %{
          name: "Room",
          description: "A description",
          listen: "Listen text",
          x: 0,
          y: 0,
          z: 0
        },
        params
      )

    Rooms.create(zone, params)
  end

  def publish_room(room) do
    room
    |> Rooms.Room.publish_changeset()
    |> Repo.update()
  end

  def create_zone(params \\ %{}) do
    params =
      Map.merge(
        %{
          name: "Zone",
          description: "A description"
        },
        params
      )

    Zones.create(params)
  end

  def publish_zone(zone) do
    zone
    |> Zones.Zone.publish_changeset()
    |> Repo.update()
  end
end
