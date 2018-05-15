defmodule Web.UserSocket do
  use Phoenix.Socket

  channel("chat:*", Web.ChatChannel)
  channel("telnet:*", Web.TelnetChannel)

  transport(:websocket, Phoenix.Transports.WebSocket)

  def connect(%{"token" => token}, socket) do
    case Phoenix.Token.verify(socket, "user socket", token, max_age: 86_400) do
      {:ok, user_id} ->
        {:ok, assign(socket, :user_id, user_id)}

      {:error, _reason} ->
        {:ok, socket}
    end
  end

  def connect(_params, socket), do: {:ok, socket}

  def id(_socket), do: nil
end
