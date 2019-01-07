defmodule Game.Account do
  @moduledoc """
  Handle database interactions for a player's account.
  """

  alias Data.ActionBar
  alias Data.Character
  alias Data.ClassProficiency
  alias Data.ClassSkill
  alias Data.Proficiency
  alias Data.RaceSkill
  alias Data.Repo
  alias Data.Save
  alias Data.Skill
  alias Data.Stats
  alias Data.User
  alias Data.User.Session
  alias ExVenture.Mailer
  alias Game.Config
  alias Game.Emails
  alias Game.Item
  alias Game.Skills

  import Ecto.Query

  @doc """
  Create a new player from attributes. Preloads everything required to start playing the game.
  """
  @spec create(map, map) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def create(attributes, %{race: race, class: class}) do
    save =
      Config.starting_save()
      |> Map.put(:stats, race.starting_stats() |> Stats.default())
      |> maybe_change_starting_room()

    attributes =
      attributes
      |> Map.put(:race_id, race.id)
      |> Map.put(:class_id, class.id)
      |> Map.put(:save, save)

    with {:ok, user} <- create_account(attributes),
         {:ok, character} <- create_character(user, attributes) do
      user |> maybe_email_welcome()

      Config.claim_character_name(character.name)

      character =
        character
        |> Repo.preload([:race])
        |> Repo.preload(class: :skills)
        |> migrate()

      {:ok, user, character}
    end
  end

  def maybe_change_starting_room(save) do
    case Config.starting_room_id() do
      nil ->
        save

      room_id ->
        Map.put(save, :room_id, room_id)
    end
  end

  defp create_account(attributes) do
    %User{}
    |> User.changeset(attributes)
    |> Repo.insert()
  end

  defp create_character(user, attributes) do
    user
    |> Ecto.build_assoc(:characters)
    |> Character.changeset(attributes)
    |> Repo.insert()
  end

  def maybe_email_welcome(player) do
    case player.email do
      nil ->
        :ok

      _ ->
        player
        |> Emails.welcome()
        |> Mailer.deliver_later()
    end
  end

  @doc """
  Save the final session data for a play
  """
  @spec save_session(User.t(), Character.t(), Save.t(), Timex.t(), Timex.t(), map()) ::
          {:ok, User.t()}
  def save_session(player, character, save, session_started_at, now, stats) do
    with {:ok, character} <- save(character, save),
         {:ok, _user} <- touch_user(character),
         {:ok, _character} <- update_time_online(character, session_started_at, now) do
      player |> create_session(session_started_at, now, stats)

      {:ok, player}
    end
  end

  @doc """
  Update the player's save data.
  """
  @spec save(Character.t(), Save.t()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def save(character, save) do
    character = %{character | save: %{}}

    character
    |> Character.changeset(%{save: save})
    |> Repo.update()
  end

  @doc """
  Touch the user on any character save
  """
  def touch_user(character) do
    character = Repo.preload(character, [:user])

    character.user
    |> Ecto.Changeset.change(%{updated_at: Timex.now() |> DateTime.truncate(:second)})
    |> Repo.update()
  end

  @doc """
  Update the seconds the player has been online.
  """
  @spec update_time_online(User.t(), Timex.t(), Timex.t()) ::
          {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def update_time_online(character, session_started_at, now) do
    character
    |> Character.changeset(%{
      seconds_online: current_play_time(character, session_started_at, now)
    })
    |> Repo.update()
  end

  @doc """
  Calculate the current play time, old + current session.
  """
  @spec current_play_time(User.t(), DateTime.t(), DateTime.t()) :: integer()
  def current_play_time(character, session_started_at, now) do
    play_time = Timex.diff(now, session_started_at, :seconds)
    character.seconds_online + play_time
  end

  @doc """
  Create a new session record
  """
  @spec create_session(User.t(), Timex.t(), Timex.t(), map) :: {:ok, User.Session.t()}
  def create_session(player, session_started_at, now, stats) do
    commands = Map.get(stats, :commands, %{})
    play_time = Timex.diff(now, session_started_at, :seconds)

    player
    |> Ecto.build_assoc(:sessions)
    |> Session.changeset(%{
      started_at: session_started_at,
      seconds_online: play_time,
      commands: commands
    })
    |> Repo.insert()
  end

  @doc """
  Hook to handle all account migrations

  - Migrate items
  """
  @spec migrate(User.t()) :: User.t()
  def migrate(player) do
    player
    |> migrate_items()
    |> migrate_skills()
    |> migrate_actions()
    |> unlock_class_proficiencies()
  end

  @doc """
  Migrate items after load

  - Ensure usable items have an amount, checks item state
  """
  @spec migrate_items(User.t()) :: User.t()
  def migrate_items(player) do
    items = player.save.items |> Enum.map(&Item.migrate_instance/1)
    %{player | save: %{player.save | items: items}}
  end

  @doc """
  Migrate skill ids after signing in

  - Ensure all global skills are present
  - Ensure all class skills are present
  - Ensure no duplicated ids
  """
  @spec migrate_skills(User.t()) :: User.t()
  def migrate_skills(player) do
    class_skill_ids =
      ClassSkill
      |> where([cs], cs.class_id == ^player.class_id)
      |> select([cs], cs.skill_id)
      |> Repo.all()

    race_skill_ids =
      RaceSkill
      |> where([cs], cs.race_id == ^player.race_id)
      |> select([cs], cs.skill_id)
      |> Repo.all()

    global_skill_ids =
      Skill
      |> where([s], s.is_global == true)
      |> select([s], s.id)
      |> Repo.all()

    skill_ids = class_skill_ids ++ race_skill_ids ++ global_skill_ids ++ player.save.skill_ids
    skill_ids = Enum.uniq(skill_ids)

    %{player | save: %{player.save | skill_ids: skill_ids}}
  end

  @doc """
  Give players a base set of actions
  """
  def migrate_actions(player) do
    case Enum.empty?(player.save.actions) do
      true ->
        actions =
          player.save.skill_ids
          |> Skills.skills()
          |> Enum.filter(fn skill ->
            skill.level <= player.save.level
          end)
          |> Enum.take(10)
          |> Enum.map(fn skill ->
            %ActionBar.SkillAction{id: skill.id}
          end)

        save =
          player.save
          |> Map.put(:actions, actions)

        %{player | save: save}

      false ->
        player
    end
  end

  @doc """
  Give players any proficiencies they are missing from their class

  Add in missing proficiencies based on character level
  """
  def unlock_class_proficiencies(player) do
    class_proficiencies =
      ClassProficiency
      |> where([cp], cp.class_id == ^player.class_id)
      |> where([cp], cp.level <= ^player.save.level)
      |> select([cp], %Proficiency.Instance{id: cp.proficiency_id, ranks: cp.ranks})
      |> Repo.all()

    existing_proficiency_ids = Enum.map(player.save.proficiencies, &(&1.id))

    proficiencies =
      class_proficiencies
      |> Enum.reject(fn instance ->
        instance.id in existing_proficiency_ids
      end)

    save = Map.put(player.save, :proficiencies, proficiencies ++ player.save.proficiencies)

    %{player | save: save}
  end

  @doc """
  Get a player by their name
  """
  @spec get_player(String.t()) :: {:ok, User.t()} | {:error, :not_found}
  def get_player(name) do
    player =
      Character
      |> where([u], fragment("lower(?) = ?", u.name, ^String.downcase(name)))
      |> preload([:class, :race, :user])
      |> limit(1)
      |> Repo.one()

    case player do
      nil ->
        {:error, :not_found}

      _ ->
        {:ok, player}
    end
  end
end
