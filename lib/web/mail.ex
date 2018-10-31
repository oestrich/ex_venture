defmodule Web.Mail do
  @moduledoc """
  Web interface for the in-game mail
  """

  import Ecto.Query

  alias Data.Mail
  alias Data.Repo
  alias Web.Character
  alias Web.Pagination

  @doc """
  Get all mail for a character
  """
  @spec all(Character.t(), opts :: Keyword.t()) :: [Zone.t()]
  def all(character, opts \\ []) do
    opts = Enum.into(opts, %{})

    Mail
    |> where([m], m.receiver_id == ^character.id)
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

  @doc """
  New mail changeset
  """
  def new(), do: %Mail{} |> Mail.changeset(%{})

  def unread_count(user) do
    Mail
    |> join(:left, [m], c in assoc(m, :receiver))
    |> where([m, c], c.user_id == ^user.id)
    |> where([m], m.is_read == false)
    |> select([m], count(m.id))
    |> Repo.one()
  end

  defdelegate mark_read!(mail), to: Game.Mail

  @doc """
  Send new mail
  """
  def send(sender, params) do
    receiver_name = Map.get(params, "receiver_name")

    case Character.get_character_by(name: receiver_name) do
      {:ok, receiver} ->
        params =
          params
          |> Map.put("sender_id", sender.id)
          |> Map.put("receiver_id", receiver.id)

        %Mail{}
        |> Mail.changeset(params)
        |> Repo.insert()

      {:error, :not_found} ->
        {:error, :receiver, :not_found}
    end
  end
end
