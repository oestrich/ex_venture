defmodule ExVenture.Users.Avatar do
  @moduledoc """
  Handle uploading avatars to remote storage for users
  """

  alias ExVenture.Images
  alias ExVenture.Users.User
  alias ExVenture.Repo
  alias Stein.Storage

  def maybe_upload_avatar(user, params) do
    params = for {key, val} <- params, into: %{}, do: {to_string(key), val}

    with {:ok, user} <- maybe_upload_avatar_image(user, params) do
      {:ok, user}
    end
  end

  @doc """
  Get a storage path for uploading and viewing the avatar image
  """
  def avatar_path(user, size) do
    avatar_path(user.id, size, user.avatar_key, user.avatar_extension)
  end

  defp avatar_path(user_id, "thumbnail", key, extension) when extension != ".png" do
    avatar_path(user_id, "thumbnail", key, ".png")
  end

  defp avatar_path(user_id, size, key, extension) do
    "/" <> Path.join(["users", to_string(user_id), "avatar", "#{size}-#{key}#{extension}"])
  end

  @doc """
  Generate an upload key
  """
  def generate_key(), do: UUID.uuid4()

  @doc """
  If the `avatar` param is available upload to storage
  """
  def maybe_upload_avatar_image(user, %{"avatar" => file}) do
    user = Images.maybe_delete_old_images(user, :avatar_key, &avatar_path/2)

    file = Storage.prep_file(file)
    key = generate_key()
    path = avatar_path(user.id, "original", key, file.extension)
    changeset = User.avatar_changeset(user, key, file.extension)

    with :ok <- Images.upload(file, path),
         {:ok, user} <- Repo.update(changeset) do
      generate_avatar_versions(user, file)
    else
      :error ->
        user
        |> Ecto.Changeset.change()
        |> Ecto.Changeset.add_error(:avatar, "could not upload, please try again")
        |> Ecto.Changeset.apply_action(:update)
    end
  end

  def maybe_upload_avatar_image(user, _), do: {:ok, user}

  @doc """
  Generate a thumbnail for the avatar image
  """
  def generate_avatar_versions(user, file) do
    path = avatar_path(user, "thumbnail")

    case Images.convert(file, extname: ".png", thumbnail: "200x200") do
      {:ok, temp_path} ->
        Images.upload(%{path: temp_path}, path)
        {:ok, user}

      {:error, :convert} ->
        {:ok, user}
    end
  end

  @doc """
  Regenerate the avatar image for a user
  """
  def regenerate_avatar(user) do
    case Storage.download(avatar_path(user, "original")) do
      {:ok, temp_path} ->
        generate_avatar_versions(user, %{path: temp_path})
    end
  end
end
