defmodule Web.Admin.ChannelController do
  use Web.AdminController

  alias Web.Channel

  def index(conn, _params) do
    channels = Channel.all()

    conn
    |> assign(:channels, channels)
    |> render("index.html")
  end

  def show(conn, %{"id" => id}) do
    channel = Channel.get(id)

    conn
    |> assign(:channel, channel)
    |> render("show.html")
  end

  def new(conn, _params) do
    changeset = Channel.new()

    conn
    |> assign(:changeset, changeset)
    |> render("new.html")
  end

  def create(conn, %{"channel" => params}) do
    case Channel.create(params) do
      {:ok, channel} ->
        conn
        |> put_flash(:info, "#{channel.name} created!")
        |> redirect(to: channel_path(conn, :index))

      {:error, changeset} ->
        conn
        |> put_flash(:error, "There was an issue creating the channel. Please try again.")
        |> assign(:changeset, changeset)
        |> render("new.html")
    end
  end

  def edit(conn, %{"id" => id}) do
    channel = Channel.get(id)
    changeset = Channel.edit(channel)

    conn
    |> assign(:channel, channel)
    |> assign(:changeset, changeset)
    |> render("edit.html")
  end

  def update(conn, %{"id" => id, "channel" => params}) do
    channel = Channel.get(id)

    case Channel.update(channel, params) do
      {:ok, _channel} ->
        conn
        |> put_flash(:info, "#{channel.name} updated!")
        |> redirect(to: channel_path(conn, :index))

      {:error, changeset} ->
        conn
        |> put_flash(:error, "There was an issue updating #{channel.name}. Please try again.")
        |> assign(:channel, channel)
        |> assign(:changeset, changeset)
        |> render("edit.html")
    end
  end
end
