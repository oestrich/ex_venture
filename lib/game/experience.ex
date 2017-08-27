defmodule Game.Experience do
  @moduledoc """
  Leveling up a character
  """

  use Networking.Socket

  alias Data.Save

  @doc """
  Apply experience points to the user's save

  Will echo experience to the socket
  """
  @spec apply(state :: map, level: integer, experience_points: integer) :: {:update, map}
  def apply(state = %{socket: socket, save: save}, level: level, experience_points: exp) do
    exp = calculate_experience(save, level, exp)
    save = add_experience(state.save, exp)

    socket |> @socket.echo("You received #{exp} experience points")

    save = case leveled_up?(state.save, save) do
      true ->
        socket |> @socket.echo("You leveled up!")
        level_up(save)
      false -> save
    end

    Map.put(state, :save, save)
  end

  @doc """
  Calculate experience for the player

  This will scale based on how close the user is to the character they beat. Too low
  and they get less experience. Higher levels generate more experience.

      iex> Game.Experience.calculate_experience(%{level: 5}, 5, 100)
      100

  Higher: 

      iex> Game.Experience.calculate_experience(%{level: 5}, 6, 100)
      120

      iex> Game.Experience.calculate_experience(%{level: 5}, 7, 100)
      140

  Lower:

      iex> Game.Experience.calculate_experience(%{level: 5}, 4, 100)
      80

      iex> Game.Experience.calculate_experience(%{level: 5}, 3, 100)
      60
  """
  @spec calculate_experience(save :: Save.t, level :: integer, exp :: integer) :: integer
  def calculate_experience(save, level, exp)
  def calculate_experience(%{level: player_level}, level, exp) do
    diff = level - player_level
    multiplier = 1 + (diff * 0.2)
    round(exp * multiplier)
  end

  @doc """
  Add experience to a user's save

      iex> Game.Experience.add_experience(%{experience_points: 100}, 100)
      %{experience_points: 200}
  """
  @spec add_experience(save :: Save.t, experience_points :: integer) :: Save.t
  def add_experience(save = %{experience_points: current_xp}, experience_points) do
    Map.put(save, :experience_points, current_xp + experience_points)
  end

  @doc """
  Check for a level up

      iex> Game.Experience.leveled_up?(%{experience_points: 900}, %{experience_points: 1000})
      true

      iex> Game.Experience.leveled_up?(%{experience_points: 1900}, %{experience_points: 2001})
      true

      iex> Game.Experience.leveled_up?(%{experience_points: 1001}, %{experience_points: 1100})
      false

      iex> Game.Experience.leveled_up?(%{experience_points: 1501}, %{experience_points: 1700})
      false
  """
  @spec leveled_up?(start_save :: Save.t, save :: Save.t) :: boolean
  def leveled_up?(start_save, save)
  def leveled_up?(%{experience_points: starting_xp}, %{experience_points: finishing_xp}) do
    div(starting_xp, 1000) < div(finishing_xp, 1000)
  end

  @doc """
  Level up after receing experience points

      iex> Game.Experience.level_up(%{level: 1, experience_points: 1000})
      %{level: 2, experience_points: 1000}

      iex> Game.Experience.level_up(%{level: 10, experience_points: 10030})
      %{level: 11, experience_points: 10030}
  """
  @spec level_up(save :: Save.t) :: Save.t
  def level_up(save = %{experience_points: xp}) do
     Map.put(save, :level, div(xp, 1000) + 1)
  end
end
