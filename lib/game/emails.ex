defmodule Game.Emails do
  @moduledoc """
  Module for game emails
  """

  alias Game.Config

  use Bamboo.Phoenix, view: Web.EmailView

  def welcome(user) do
    base_email()
    |> to(user.email)
    |> subject("Welcome to #{Config.game_name()}")
    |> render("welcome.text", user: user)
  end

  def new_mail(mail) do
    base_email()
    |> to(mail.receiver.user.email)
    |> subject("You have new mail in #{Config.game_name()}")
    |> render("mail.html", mail: mail)
    |> render("mail.text", mail: mail)
  end

  def password_reset(user) do
    base_email()
    |> to(user.email)
    |> subject("Password reset for #{Config.game_name()}")
    |> render("reset.html", user: user)
  end

  def base_email() do
    from_email = Application.get_env(:ex_venture, :mailer)[:from]

    new_email()
    |> from(ExVenture.config(from_email))
  end
end
