defmodule Game.Emails do
  @moduledoc """
  Module for game emails
  """

  alias Game.Config

  use Bamboo.Phoenix, view: Web.EmailView

  @from_email Application.get_env(:ex_venture, :mailer)[:from]

  def welcome(user) do
    base_email()
    |> to(user.email)
    |> subject("Welcome to #{Config.game_name()}")
    |> render("welcome.text", user: user)
  end

  def new_mail(mail) do
    base_email()
    |> to(mail.receiver.email)
    |> subject("You have new mail in #{Config.game_name()}")
    |> render("mail.html", mail: mail)
    |> render("mail.text", mail: mail)
  end

  def base_email() do
    new_email()
    |> from(ExVenture.config(@from_email))
  end
end
