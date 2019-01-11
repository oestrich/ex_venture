defmodule Web.CharacterChannel do
  @moduledoc """
  CharacterChannel for admins
  """

  use Phoenix.Channel

  require Logger

  def join("character:" <> id, _message, socket) do
    %{user: user} = socket.assigns
    {id, _} = Integer.parse(id)

    socket =
      socket
      |> assign(:character_id, id)

    Logger.info("Admin (#{user.id}) is watching character (#{id})")
    :telemetry.execute([:exventure, :admin, :user, :watch], 1)

    {:ok, socket}
  end
end
