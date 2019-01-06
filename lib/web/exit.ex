defmodule Web.Exit do
  @moduledoc """
  Context for in game exits
  """

  alias Data.Exit
  alias Data.Repo

  @doc """
  Create an exit

  room <-> room
  overworld <-> room
  """
  @spec create_exit(params :: map) :: {:ok, Exit.t()} | {:error, changeset :: map}
  def create_exit(params) do
    params =
      params
      |> maybe_add_door_id()
      |> cast_params()

    changeset = %Exit{} |> Exit.changeset(params)
    reverse_changeset = %Exit{} |> Exit.changeset(reverse_params(params))

    with {:ok, room_exit} <- Repo.insert(changeset),
         {:ok, reverse_exit} <- Repo.insert(reverse_changeset) do
      {:ok, room_exit, reverse_exit}
    end
  end

  defp maybe_add_door_id(params) do
    case Map.get(params, "has_door", false) do
      true ->
        Map.put(params, "door_id", UUID.uuid4())

      "true" ->
        Map.put(params, "door_id", UUID.uuid4())

      _ ->
        params
    end
  end

  defp cast_params(params) do
    params
    |> parse_proficiencies()
  end

  defp parse_proficiencies(params = %{"proficiencies" => proficiencies}) do
    case Poison.decode(proficiencies) do
      {:ok, proficiencies} ->
        Map.put(params, "proficiencies", proficiencies)

      _ ->
        params
    end
  end

  defp parse_proficiencies(params), do: params

  defp reverse_params(params) do
    reverse_params = %{
      direction: to_string(Exit.opposite(params["direction"])),
      has_door: Map.get(params, "has_door", false),
      door_id: Map.get(params, "door_id", nil),
      proficiencies: Map.get(params, "proficiencies", [])
    }

    reverse_params
    |> add_start(params)
    |> add_finish(params)
  end

  defp add_start(reverse_params, params) do
    case params do
      %{"finish_room_id" => finish_room_id} ->
        Map.put(reverse_params, :start_room_id, finish_room_id)

      %{"finish_overworld_id" => finish_overworld_id} ->
        reverse_params
        |> Map.put(:start_overworld_id, finish_overworld_id)
        |> Map.put(:start_zone_id, params["finish_zone_id"])

      _ ->
        reverse_params
    end
  end

  defp add_finish(reverse_params, params) do
    case params do
      %{"start_room_id" => start_room_id} ->
        Map.put(reverse_params, :finish_room_id, start_room_id)

      %{"start_overworld_id" => start_overworld_id} ->
        reverse_params
        |> Map.put(:finish_overworld_id, start_overworld_id)
        |> Map.put(:finish_zone_id, params["start_zone_id"])

      _ ->
        reverse_params
    end
  end

  @doc """
  Delete an exit and its opposite

  room <-> room
  overworld <-> room
  """
  @spec delete_exit(params :: map) :: {:ok, Exit.t()} | {:error, changeset :: map}
  def delete_exit(exit_id) do
    room_exit = Exit |> Repo.get(exit_id)

    reverse_exit =
      Exit
      |> Repo.get_by(
        [
          direction: to_string(Exit.opposite(room_exit.direction))
        ] ++ reverse_id(room_exit)
      )

    with {:ok, room_exit} <- Repo.delete(room_exit),
         {:ok, reverse_exit} <- Repo.delete(reverse_exit) do
      {:ok, room_exit, reverse_exit}
    end
  end

  defp reverse_id(room_exit) do
    case room_exit do
      %{start_room_id: start_room_id} when start_room_id != nil ->
        [finish_room_id: room_exit.start_room_id]

      %{start_overworld_id: start_overworld_id} when start_overworld_id != nil ->
        [finish_overworld_id: room_exit.start_overworld_id]
    end
  end

  @doc """
  Reload the corresponding process for the exit
  """
  @spec reload_process(Exit.t()) :: Exit.t()
  def reload_process(room_exit) do
    case room_exit do
      %{start_room_id: start_room_id} when start_room_id != nil ->
        Web.Room.update_exit(room_exit)

      %{start_overworld_id: start_overworld_id} when start_overworld_id != nil ->
        Web.Zone.update_exit(room_exit)
    end
  end
end
