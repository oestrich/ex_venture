defmodule ExVenture.Emails do
  @moduledoc false

  use Bamboo.Phoenix, view: ExVenture.Emails.EmailView

  import Web.Gettext, only: [gettext: 1]

  alias Web.Endpoint
  alias Web.Router.Helpers, as: Routes

  def welcome_email(user) do
    confirm_url = Routes.confirmation_url(Endpoint, :confirm, code: user.email_verification_token)

    base_email()
    |> to(user.email)
    |> subject("Welcome to #{gettext("ExVenture")}!")
    |> assign(:confirm_url, confirm_url)
    |> render(:welcome)
  end

  def verify_email(user) do
    confirm_url = Routes.confirmation_url(Endpoint, :confirm, code: user.email_verification_token)

    base_email()
    |> to(user.email)
    |> subject("Please verify your email address")
    |> assign(:confirm_url, confirm_url)
    |> render(:verify_email)
  end

  def password_reset(user) do
    reset_url = Routes.registration_reset_url(Endpoint, :edit, token: user.password_reset_token)

    base_email()
    |> to(user.email)
    |> subject("Password reset for #{gettext("ExVenture")}")
    |> render("password-reset.html", reset_url: reset_url)
  end

  defp base_email() do
    new_email()
    |> from("no-reply@example.com")
  end

  defmodule EmailView do
    @moduledoc false

    use Phoenix.View, root: "lib/ex_venture/emails/templates", path: ""
    use Phoenix.HTML

    import Web.Gettext, only: [gettext: 1]
  end
end
