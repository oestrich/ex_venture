defmodule Test.Game.Environment do
  alias Test.Game.Room

  def link(_id), do: :ok

  def unlink(_id), do: :ok

  def look(id) do
    Room.look(id)
  end

  def enter(id, who, reason) do
    Room.enter(id, who, reason)
  end

  def leave(id, who, reason) do
    Room.leave(id, who, reason)
  end

  def notify(id, character, event) do
    Room.notify(id, character, event)
  end

  def pick_up(id, item) do
    Room.pick_up(id, item)
  end

  def pick_up_currency(id) do
    Room.pick_up_currency(id)
  end

  def drop(id, who, item) do
    Room.drop(id, who, item)
  end

  def drop_currency(id, who, currency) do
    Room.drop_currency(id, who, currency)
  end

  def update_character(id, character) do
    Room.update_character(id, character)
  end

  def crash(id) do
    Room.crash(id)
  end
end
