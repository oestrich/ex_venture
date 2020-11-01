defmodule ExVenture.TestHelpers do
  @moduledoc """
  Test Helpers for creating database records
  """

  alias ExVenture.Repo
  alias ExVenture.Users
  alias ExVenture.Zones

  def create_user(params \\ %{}) do
    params =
      Map.merge(
        %{
          email: "user@example.com",
          first_name: "John",
          last_name: "Smith",
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
end
