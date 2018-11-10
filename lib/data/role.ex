defmodule Data.Role do
  @moduledoc """
  Role schema
  """

  use Data.Schema

  @resources [
    "items",
    "npcs",
    "quests",
    "rooms",
    "users",
    "zones",
  ]

  @accesses [
    "read",
    "write",
  ]

  schema "roles" do
    field(:name, :string)
    field(:permissions, {:array, :string}, default: [])

    timestamps()
  end

  @doc """
  Set of resources that are handled by permissioning
  """
  def resources(), do: @resources

  @doc """
  Types of accesses available to each resource

      iex> Role.accesses()
      ["read", "write"]
  """
  def accesses(), do: @accesses

  @doc """
  A combination of resources and accesses

      iex> "rooms/read" in Role.permissions()
      true
  """
  def permissions() do
    Enum.flat_map(@resources, fn resource ->
      Enum.map(@accesses, fn access ->
        "#{resource}/#{access}"
      end)
    end)
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:name, :permissions])
    |> validate_required([:name, :permissions])
    |> validate_permissions()
  end

  defp validate_permissions(changeset) do
    case get_field(changeset, :permissions) do
      nil ->
        changeset

      permissions ->
        case Enum.all?(permissions, &valid_permission?/1) do
          true ->
            changeset

          false ->
            add_error(changeset, :permissions, "are invalid")
        end
    end
  end

  @doc """
  Check if a permission is valid

      iex> Role.valid_permission?("rooms/read")
      true

      iex> Role.valid_permission?("unknown/read")
      false

      iex> Role.valid_permission?("unknown")
      false
  """
  def valid_permission?(permission) do
    Enum.member?(permissions(), permission)
  end
end
