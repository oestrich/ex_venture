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

  def base_email() do
    new_email()
    |> from(ExVenture.config(@from_email))
  end
end
