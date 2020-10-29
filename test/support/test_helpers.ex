defmodule ExVenture.TestHelpers do
  @moduledoc """
  Test Helpers for creating database records
  """

  alias ExVenture.Users

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
end
