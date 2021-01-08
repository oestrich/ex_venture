defmodule Web.PageView do
  use Web, :view

  alias Web.ReactView

  def characters_for_client(characters) do
    Enum.map(characters, fn character ->
      %{
        name: character.name,
        token: Phoenix.Token.sign(Web.Endpoint, "character id", character.id)
      }
    end)
  end
end
