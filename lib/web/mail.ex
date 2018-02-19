defmodule Web.Mail do
  @moduledoc """
  Web interface for the in-game mail
  """

  import Ecto.Query

  alias Data.Mail
  alias Data.Repo
  alias Web.Pagination

  @doc """
  Get all mail for a user
  """
  @spec all(User.t(), opts :: Keyword.t()) :: [Zone.t()]
  def all(user, opts \\ []) do
    opts = Enum.into(opts, %{})

    Mail
    |> where([m], m.receiver_id == ^user.id)
    |> preload([:sender])
    |> order_by([z], desc: z.id)
    |> Pagination.paginate(opts)
  end

  @doc """
  Load a piece of mail
  """
  def get(id) do
    Mail |> Repo.get(id) |> Repo.preload([:sender])
  end

  def unread_count(user) do
    Mail
    |> where([m], m.receiver_id == ^user.id)
    |> where([m], m.is_read == false)
    |> select([m], count(m.id))
    |> Repo.one()
  end

  defdelegate mark_read!(mail), to: Game.Mail
end
