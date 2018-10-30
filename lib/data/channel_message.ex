defmodule Data.ChannelMessage do
  @moduledoc """
  In game messages that went to a channel
  """

  use Data.Schema

  alias Data.Channel
  alias Data.Character

  schema "channel_messages" do
    field(:message, :string)
    field(:formatted, :string)

    belongs_to(:channel, Channel)
    belongs_to(:character, Character)

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:message, :formatted, :channel_id, :character_id])
    |> validate_required([:message, :formatted, :channel_id, :character_id])
    |> foreign_key_constraint(:channel_id)
    |> foreign_key_constraint(:character_id)
  end
end
