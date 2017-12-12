defmodule Game.Session.Effects do
  @moduledoc """
  Handle effects on a user
  """

  alias Game.Character
  alias Game.Effect
  alias Game.Format

  import Game.Session, only: [echo: 2]
  import Game.Character.Update, only: [update_character: 2]

  @doc """
  Apply effects after receiving them from a targeter

  Used from the character callback `{:apply_effects, effects, from, description}`.
  """
  @spec apply(effects :: [Data.Effect.t], from :: tuple, description :: String.t, state :: Map) :: map
  def apply(effects, from, description, state) do
    %{user: user, save: save, is_targeting: is_targeting} = state

    stats = effects |> Effect.apply(save.stats)

    save = Map.put(save, :stats, stats)
    user = Map.put(user, :save, save)
    save.room_id |> update_character(user)

    user_id = user.id
    description =
      case Character.who(from) do
        {:user, ^user_id} -> Format.effects(effects)
        _ -> [description | Format.effects(effects)]
      end
    echo(self(), description |> Enum.join("\n"))

    user |> notify_targeters(stats, is_targeting)

    state
    |> Map.put(:user, user)
    |> Map.put(:save, save)
  end

  @doc """
  Notify targets of death if health is < 1
  """
  @spec notify_targeters(user :: Data.User.t, state :: map, is_targeting :: []) :: nil
  def notify_targeters(user, state, is_targeting)
  def notify_targeters(user, %{health: health}, is_targeting) when health < 1 do
    Enum.each(is_targeting, &(Character.died(&1, {:user, user})))
  end
  def notify_targeters(_user, _stats, _is_targeting), do: nil
end
