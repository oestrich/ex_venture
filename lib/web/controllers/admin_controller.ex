defmodule Web.AdminController do
  defmacro __using__(_opts) do
    quote do
      use Web, :controller

      plug :put_layout, "admin.html"
      plug :load_user
      plug :ensure_user!
      plug :ensure_admin!

      defp load_user(conn, _opts) do
        case conn |> get_session(:user_token) do
          nil -> conn
          token -> conn |> _load_user(Web.User.from_token(token))
        end
      end

      defp _load_user(conn, nil), do: conn
      defp _load_user(conn, user), do: conn |> assign(:user, user)

      defp ensure_user!(conn, _opts) do
        case Map.has_key?(conn.assigns, :user) do
          true -> conn
          false -> conn |> redirect(to: session_path(conn, :new)) |> halt()
        end
      end

      defp ensure_admin!(conn, _opts) do
        %{user: user} = conn.assigns

        case "admin" in user.flags do
          true -> conn
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
