defmodule Web.AuthConnCase do
  defmacro __using__(_opts) do
    quote do
      use Web.ConnCase

      setup %{conn: conn} do
        user = create_admin_user(%{name: "user", password: "password"})
        character = create_character(user, %{name: "user"})
        user = %{user | characters: [character]}

        conn = conn |> assign(:current_user, user)

        %{conn: conn, user: user, character: character}
      end
    end
  end
end
