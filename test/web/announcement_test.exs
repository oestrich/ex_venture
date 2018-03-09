defmodule Web.AnnouncementTest do
  use Data.ModelCase

  alias Web.Announcement

  test "creating a announcement" do
    params = %{
      "title" => "Gods",
      "body" => "There are some gods here",
      "tags" => "gods,magic",
    }

    {:ok, announcement} = Announcement.create(params)

    assert announcement.title == "Gods"
    assert announcement.tags == ["gods", "magic"]
  end

  test "updating a announcement" do
    announcement = create_announcement(%{title: "Fighter"})

    {:ok, announcement} = Announcement.update(announcement.id, %{title: "Barbarians"})

    assert announcement.title == "Barbarians"
  end
end
