defmodule Data.HelpTopic do
  @moduledoc """
  Help Topicschema
  """

  use Data.Schema

  schema "help_topics" do
    field :name, :string
    field :keywords, {:array, :string}
    field :body, :string

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:name, :keywords, :body])
    |> validate_required([:name, :keywords, :body])
  end
end
