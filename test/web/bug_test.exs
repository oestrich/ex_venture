defmodule Web.BugTest do
  use Data.ModelCase

  alias Web.Bug

  test "mark a bug as complete" do
    user = create_user(%{name: "reporter", password: "password"})
    bug = create_bug(user, %{title: "A bug", body: "more details"})

    {:ok, bug} = Bug.complete(bug.id)

    assert bug.is_completed
  end
end
