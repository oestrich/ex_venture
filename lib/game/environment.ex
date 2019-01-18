defmodule Game.Environment do
  @moduledoc """
  Look at your surroundings, whether a room or an overworld
  """

  @environment Application.get_env(:ex_venture, :game)[:environment]

  @doc """
  Get the type of room based on its id
  """
  def room_type(room_id) do
    case room_id do
      "overworld:" <> _id ->
        :overworld

      _ ->
        :room
    end
  end

  def look(room_id) do
    @environment.look(room_id)
  end

  def enter(room_id, character, reason) do
    @environment.enter(room_id, character, reason)
  end

  def leave(room_id, character, reason) do
    @environment.leave(room_id, character, reason)
  end

  def notify(room_id, character, event) do
    @environment.notify(room_id, character, event)
  end

  def say(room_id, sender, message) do
    @environment.say(room_id, sender, message)
  end

  def emote(room_id, sender, message) do
    @environment.emote(room_id, sender, message)
  end

  def pick_up(room_id, item) do
    @environment.pick_up(room_id, item)
  end

  def pick_up_currency(room_id) do
    @environment.pick_up_currency(room_id)
  end

  def drop(room_id, character, item) do
    @environment.drop(room_id, character, item)
  end

  def drop_currency(room_id, character, currency) do
    @environment.drop_currency(room_id, character, currency)
  end

  def update_character(room_id, character) do
    @environment.update_character(room_id, character)
  end

  def link(room_id) do
    @environment.link(room_id)
  end

  def unlink(room_id) do
    @environment.unlink(room_id)
  end

  def crash(room_id) do
    @environment.crash(room_id)
  end
end
