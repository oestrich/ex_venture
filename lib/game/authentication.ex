defmodule Game.Authentication do
  @moduledoc """
  Find and validate a user
  """
  import Ecto.Query

  alias Data.Repo
  alias Data.Skill
  alias Data.User

  @doc """
  Attempt to find a user and validate their password
  """
  @spec find_and_validate(name :: String.t, password :: String.t) :: {:error, :invalid} | User.t
  def find_and_validate(name, password) do
    user = User
    |> where([u], u.name == ^name)
    |> preload([:race])
    |> preload([class: [skills: ^(from s in Skill, order_by: [s.level, s.id])]])
    |> Repo.one
    _find_and_validate(user, password)
  end

  defp _find_and_validate(nil, _password) do
    Comeonin.Bcrypt.dummy_checkpw
    {:error, :invalid}
  end
  defp _find_and_validate(user, password) do
    case Comeonin.Bcrypt.checkpw(password, user.password_hash) do
      true -> user
      _ -> {:error, :invalid}
    end
  end
end
