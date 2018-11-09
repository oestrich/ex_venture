defmodule Web.CharacterSocket do
  use Phoenix.Socket

  channel("chat:*", Web.ChatChannel)
  channel("telnet:*", Web.TelnetChannel)

  def connect(%{"token" => token}, socket) do
    case Phoenix.Token.verify(socket, "character socket", token, max_age: 86_400) do
      {:ok, character_id} ->
        {:ok, assign(socket, :character_id, character_id)}

      {:error, _reason} ->
        {:ok, socket}
    end
  end

  def connect(_params, socket), do: {:ok, socket}

  def id(_socket), do: nil
end
