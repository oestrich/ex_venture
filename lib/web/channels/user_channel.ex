defmodule Web.UserChannel do
  @moduledoc """
  User Channel for admins
  """

  use Phoenix.Channel

  require Logger

  alias Metrics.AdminInstrumenter

  def join("user:" <> id, _message, socket) do
    %{user: user} = socket.assigns
    {id, _} = Integer.parse(id)

    socket =
      socket
      |> assign(:user_id, id)

    Logger.info("Admin (#{user.id}) is watching user (#{id})")
    AdminInstrumenter.watching_player()

    {:ok, socket}
  end
end
