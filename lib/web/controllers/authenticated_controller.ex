defmodule Web.AuthenticatedController do
  defmacro __using__(_opts) do
    quote do
      use Web, :controller

      plug(:load_user)

      defp load_user(conn, _opts) do
        case conn |> get_session(:user_token) do
          nil -> conn
          token -> conn |> _load_user(Web.User.from_token(token))
        end
      end

      defp _load_user(conn, nil), do: conn
      defp _load_user(conn, user), do: conn |> assign(:user, user)
    end
  end
end
