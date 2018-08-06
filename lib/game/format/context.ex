defmodule Game.Format.Context do
  @moduledoc """
  Context token struct for formatting and templating.

  Similar to a Phoenix connection struct
  """

  @doc """
  Context struct for formatting strings

  - `assigns`: map of key/values to template
  """
  defstruct [assigns: %{}]

  @doc """
  Start with a base conntext
  """
  def context() do
    %__MODULE__{}
  end

  @doc """
  Assign a new template variable
  """
  def assign(context, key, value) do
    assigns =
      context
      |> Map.get(:assigns, %{})
      |> Map.put(key, value)

    %{context | assigns: assigns}
  end

  def assign(context, map) do
    assigns =
      context
      |> Map.get(:assigns, %{})

    assigns = Enum.into(map, assigns)

    %{context | assigns: assigns}
  end
end
