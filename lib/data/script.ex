defmodule Data.Script do
  @moduledoc """
  In game script that the NPC uses to converse with players
  """

  import Ecto.Changeset

  alias Data.Script.Line

  @type t :: [Line.t()]

  @doc """
  Validate that the conversation is good to use for an npc. None of the lines
  can have a `trigger: "quest"` in them.

      iex> Data.Script.valid_for_npc?([%Data.Script.Line{key: "start", message: "Hello", trigger: "quest"}])
      false

      iex> Data.Script.valid_for_npc?([%Data.Script.Line{key: "start", message: "Hello"}])
      true
  """
  @spec valid_for_npc?([t()]) :: boolean()
  def valid_for_npc?(script) do
    Enum.all?(script, fn line ->
      line.trigger != "quest"
    end)
  end

  @doc """
  Validate that the conversation is good to use for a quest. Any of the lines
  must have a `trigger: "quest"` in them.

      iex> Data.Script.valid_for_quest?([%Data.Script.Line{key: "start", message: "Hello", trigger: "quest"}])
      true

      iex> Data.Script.valid_for_quest?([%Data.Script.Line{key: "start", message: "Hello"}])
      false
  """
  @spec valid_for_quest?([t()]) :: boolean()
  def valid_for_quest?(script) do
    Enum.any?(script, fn line ->
      line.trigger == "quest"
    end)
  end

  @doc """
  Validate the script of the NPC
  """
  @spec validate_script(changeset :: Ecto.Changeset.t) :: Ecto.Changeset.t
  def validate_script(changeset) do
    case get_change(changeset, :script) do
      nil -> changeset
      script-> _validate_script(changeset, script)
    end
  end

  defp _validate_script(changeset, script) do
    case valid_script?(script) do
      true -> changeset
      false -> add_error(changeset, :script, "are invalid")
    end
  end

  @doc """
  Check if all lines in a script are valid
  """
  @spec valid_script?([t()]) :: boolean()
  def valid_script?(script) do
    Enum.all?(script, &Line.valid?/1) &&
      contains_start_key?(script) &&
      keys_are_all_included?(script)
  end

  defp contains_start_key?(script) do
    Enum.any?(script, fn (line) ->
      line.key == "start"
    end)
  end

  defp keys_are_all_included?(script) do
    Enum.all?(script, fn (line) ->
      Enum.all?(line.listeners, fn (listener) ->
        Enum.any?(script, fn (line) ->
          listener.key == line.key
        end)
      end)
    end)
  end
end
