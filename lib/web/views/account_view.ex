defmodule Web.AccountView do
  use Web, :view

  alias Web.Mail
  alias Web.User

  def provider_login?(user) do
    user.provider != nil
  end
end
