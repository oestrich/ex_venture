defmodule Web.AdminSocket do
  use Phoenix.Socket
  require Logger

  alias Web.User

  channel "npc:*", Web.NPCChannel

  transport :websocket, Phoenix.Transports.WebSocket

  def connect(%{"token" => token}, socket) do
    case Phoenix.Token.verify(socket, "user socket", token, max_age: 86_400) do
      {:ok, user_id} ->
        socket |> authenticate_user(User.get(user_id))
      {:error, _reason} ->
        :error
    end
  end

  defp authenticate_user(_socket, nil), do: :error
  defp authenticate_user(socket, user) do
    case "admin" in user.flags do
      true ->
        Logger.info("Admin is connecting")
        {:ok, assign(socket, :user, user)}
      false ->
        :error
    end
  end

  def id(_socket), do: nil
end
