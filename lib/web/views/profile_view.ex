defmodule Web.ProfileView do
  use Web, :view

  alias ExVenture.Users.Avatar

  def full_name(user), do: "#{user.first_name} #{user.last_name}"

  def avatar?(user), do: user.avatar_key != nil

  def avatar_img(user) do
    link(to: Stein.Storage.url(Avatar.avatar_path(user, "original"))) do
      img_tag(Stein.Storage.url(Avatar.avatar_path(user, "thumbnail")))
    end
  end
end
