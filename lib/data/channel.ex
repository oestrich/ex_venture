defmodule Data.Channel do
  @moduledoc """
  In game communication channel schema
  """

  use Data.Schema

  alias Data.ChannelMessage
  alias Data.Color

  schema "channels" do
    field(:name, :string)
    field(:color, :string, default: "red")
    field(:is_gossip_connected, :boolean, default: false)
    field(:gossip_channel, :string)

    has_many(:messages, ChannelMessage)

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:name, :color, :is_gossip_connected, :gossip_channel])
    |> validate_required([:name, :color, :is_gossip_connected])
    |> validate_gossip_channel()
    |> validate_inclusion(:color, Color.options())
    |> validate_single_word_name()
  end

  defp validate_single_word_name(changeset) do
    case get_field(changeset, :name) do
      name when name != nil ->
        case length(String.split(name)) do
          1 -> changeset
          _ -> add_error(changeset, :name, "must be a single word")
        end

      _ ->
        changeset
    end
  end

  defp validate_gossip_channel(changeset) do
    case get_field(changeset, :is_gossip_connected) do
      true ->
        validate_required(changeset, [:gossip_channel])

      _ ->
        put_change(changeset, :gossip_channel, nil)
    end
  end
end
