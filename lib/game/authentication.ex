defmodule Game.Authentication do
  import Ecto.Query

  alias Data.Repo
  alias Data.User

  def find_and_validate(username, password) do
    user = User |> where([u], u.username == ^username) |> Repo.one
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
