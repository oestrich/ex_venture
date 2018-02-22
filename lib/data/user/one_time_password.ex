defmodule Data.User.OneTimePassword do
  @moduledoc """
  OTP schema
  """

  use Data.Schema

  alias Data.User

  schema "one_time_passwords" do
    field(:password, Ecto.UUID)
    field(:used_at, Timex.Ecto.DateTime)

    belongs_to(:user, User)

    timestamps()
  end

  def changeset(struct) do
    struct
    |> change()
    |> put_change(:password, UUID.uuid4())
    |> validate_required([:password, :user_id])
    |> foreign_key_constraint(:user_id)
  end

  def used_changeset(struct) do
    struct
    |> change()
    |> put_change(:used_at, Timex.now())
  end
end
