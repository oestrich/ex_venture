defmodule Web.AdminController do
  defmacro __using__(_opts) do
    quote do
      use Web, :controller

      plug(:put_layout, "admin.html")
      plug(Web.Plug.LoadUser)
      plug(Web.Plug.LoadCharacter)
      plug(:ensure_user!)
      plug(:ensure_admin!)

      defp ensure_user!(conn, _opts) do
        case Map.has_key?(conn.assigns, :user) do
          true ->
            conn

          false ->
            conn |> redirect(to: session_path(conn, :new)) |> halt()
        end
      end

      defp ensure_admin!(conn, _opts) do
        %{user: user} = conn.assigns

        case "admin" in user.flags do
          true ->
            conn

          false ->
            conn
            |> put_session(:user_token, nil)
            |> redirect(to: session_path(conn, :new))
            |> halt()
        end
      end
    end
  end
end
