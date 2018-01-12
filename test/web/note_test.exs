defmodule Web.NoteTest do
  use Data.ModelCase

  alias Web.Note

  test "creating a note" do
    params = %{
      "name" => "Gods",
      "body" => "There are some gods here",
      "tags" => "gods,magic",
    }

    {:ok, note} = Note.create(params)

    assert note.name == "Gods"
    assert note.tags == ["gods", "magic"]
  end

  test "updating a note" do
    note = create_note(%{name: "Fighter"})

    {:ok, note} = Note.update(note.id, %{name: "Barbarians"})

    assert note.name == "Barbarians"
  end
end
