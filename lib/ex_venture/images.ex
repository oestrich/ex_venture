defmodule ExVenture.Images do
  @moduledoc """
  Common module for dealing with image conversion
  """

  @type opts() :: Keyword.t()

  alias Stein.Storage
  alias Stein.Storage.FileUpload

  @doc """
  Convert an image file using image magick
  """
  @spec convert(FileUpload.t(), opts()) :: {:ok, Path.t()} | {:error, :convert}
  def convert(file, opts) do
    {:ok, temp_path} = Stein.Storage.Temp.create(extname: Keyword.get(opts, :extname))

    case Porcelain.exec("convert", convert_args(file.path, temp_path, opts)) do
      %{status: 0} ->
        {:ok, temp_path}

      _ ->
        {:error, :convert}
    end
  end

  defp convert_args(file_path, temp_path, opts) do
    [file_path | opt_args(opts)] ++ [temp_path]
  end

  defp opt_args([]), do: []

  defp opt_args([opt | opts]) do
    case opt do
      {:thumbnail, size} ->
        ["-thumbnail", "#{size}^", "-gravity", "center", "-extent", size] ++ opt_args(opts)

      _ ->
        opt_args(opts)
    end
  end

  @doc """
  Delete the old images for the passed in struct

  Deletes original and thumbnail sizes if present.
  """
  def maybe_delete_old_images(struct, key, path_fun) do
    case is_nil(Map.get(struct, key)) do
      true ->
        struct

      false ->
        Storage.delete(path_fun.(struct, "original"))
        Storage.delete(path_fun.(struct, "thumbnail"))

        struct
    end
  end

  @doc """
  Upload the file to the path in storage
  """
  def upload(file, path) do
    Storage.upload(file, path, extensions: [".jpg", ".png"], public: true)
  end
end
