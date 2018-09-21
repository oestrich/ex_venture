defmodule Data.ActionBar do
  @moduledoc """
  ActionBar data
  """

  @type action :: Data.ActionBar.SkillAction.t() | Data.ActionBar.CommandAction.t()

  defmodule SkillAction do
    @moduledoc """
    Skill action bar button

    For one of the player's skills
    """

    @type t :: %__MODULE__{}

    defstruct [:id, type: "skill"]
  end

  defmodule CommandAction do
    @moduledoc """
    Command action bar button

    A generic command that the game will send
    """

    @type t :: %__MODULE__{}

    defstruct [:command, :name, type: "command"]
  end

  def maybe_add_action(save, action) do
    case length(save.actions) < 10 do
      true ->
        actions = Enum.reverse([action | Enum.reverse(save.actions)])
        %{save | actions: actions}

      false ->
        save
    end
  end
end
