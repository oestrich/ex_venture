defmodule Data.Events.Options do
  @moduledoc """
  Options parsing for events and actions
  """

  @doc """
  Validate a set of event options coming in
  """
  def validate_options(event_type, options) do
    options = Enum.map(event_type.options(), &parse_option(&1, options))

    case Enum.any?(options, &elem(&1, 0) == :error) do
      true ->
        errors =
          options
          |> Enum.filter(&elem(&1, 0) == :error)
          |> Enum.map(&elem(&1, 1))
          |> Enum.into(%{})

        {:error, errors}

      false ->
        options =
          options
          |> Enum.filter(&elem(&1, 0) == :ok)
          |> Enum.map(&elem(&1, 1))
          |> Enum.reject(&is_nil/1)
          |> Enum.into(%{})

        {:ok, options}
    end
  end

  defp parse_option({key, type}, options) do
    with {:ok, value} <- Map.fetch(options, to_string(key)) do
      case valid_option_value?(type, value) do
        true ->
          {:ok, {key, value}}

        false ->
          {:error, {key, "invalid"}}
      end
    else
      :error ->
        {:ok, nil}
    end
  end

  @doc """
  Validate option value

      iex> Options.valid_option_value?(:integer, 10)
      true
      iex> Options.valid_option_value?(:integer, "string")
      false

      iex> Options.valid_option_value?(:float, 10)
      true
      iex> Options.valid_option_value?(:float, 10.0)
      true
      iex> Options.valid_option_value?(:float, "string")
      false

      iex> Options.valid_option_value?(:boolean, true)
      true
      iex> Options.valid_option_value?(:boolean, false)
      true
      iex> Options.valid_option_value?(:boolean, "string")
      false

      iex> Options.valid_option_value?(:string, "string")
      true
      iex> Options.valid_option_value?(:string, 10)
      false

      iex> Options.valid_option_value?({:array, :string}, ["string"])
      true
      iex> Options.valid_option_value?({:array, :string}, ["string", 10])
      false
      iex> Options.valid_option_value?({:array, :string}, 10)
      false
  """
  def valid_option_value?(type, value) do
    case type do
      :boolean ->
        is_boolean(value)

      :float ->
        is_integer(value) || is_float(value)

      :integer ->
        is_integer(value)

      :string ->
        is_binary(value)

      {:array, :string} ->
        is_list(value) && Enum.all?(value, &is_binary/1)

      _ ->
        false
    end
  end
end
