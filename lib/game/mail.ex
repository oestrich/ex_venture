defmodule Game.Mail do
  @moduledoc """
  Helpers for dealing with the mail system
  """

  import Ecto.Query

  alias Data.Mail
  alias Data.Repo
  alias Data.User

  @doc """
  Get mail for a user
  """
  @spec mail_for(User.t()) :: [Mail.t()]
  def mail_for(user) do
    Mail
    |> where([m], m.receiver_id == ^user.id)
    |> preload([:sender])
    |> Repo.all()
  end

  @doc """
  Get mail for a user
  """
  @spec get(User.t(), integer()) :: Mail.t() | nil
  def get(receiver, id) do
    Mail
    |> Repo.get_by(receiver_id: receiver.id, id: id)
    |> Repo.preload([:sender])
  end
end
