defmodule Web.MailController do
  use Web, :controller

  alias Web.Mail

  plug(Web.Plug.PublicEnsureUser)
  plug(Web.Plug.FetchPage when action in [:index])

  plug(:load_mail when action in [:show])
  plug(:ensure_your_mail! when action in [:show])

  def index(conn, _params) do
    %{user: user, page: page, per: per} = conn.assigns
    %{page: mail, pagination: pagination} = Mail.all(user, page: page, per: per)
    conn |> render("index.html", mail_pieces: mail, pagination: pagination)
  end

  def show(conn, _params) do
    %{mail: mail} = conn.assigns
    Mail.mark_read!(mail)
    conn |> render("show.html")
  end

  defp load_mail(conn, _opts) do
    case conn.params do
      %{"id" => id} ->
        case Mail.get(id) do
          nil ->
            conn |> redirect(to: public_mail_path(conn, :index)) |> halt()

          mail ->
            conn |> assign(:mail, mail)
        end

      _ ->
        conn |> redirect(to: public_mail_path(conn, :index)) |> halt()
    end
  end

  defp ensure_your_mail!(conn, _opts) do
    %{user: user, mail: mail} = conn.assigns

    case user.id == mail.receiver_id do
      true ->
        conn

      false ->
        conn |> redirect(to: public_mail_path(conn, :index)) |> halt()
    end
  end
end
