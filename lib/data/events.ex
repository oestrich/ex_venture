defmodule Data.Events do
  @moduledoc """
  Eventing layer

  An event looks like this:

  ```json
  {
    "type": "room/entered",
    "actions": [
      {
        "type": "communications/emote",
        "delay": 0.5,
        "options": {
          "message": "[name] glances up from reading his paper",
        }
      },
      {
        "type": "communications/say",
        "delay": 0.75,
        "options": {
          "message": "Welcome!"
        }
      },
      {
        "type": "communications/say",
        "delay": 0.75,
        "options": {
          "message": "How can I help you?"
        }
      }
    ]
  }
  ```
  """

  @type action :: String.t()

  @type options_mapping :: map()

  @callback type() :: String.t()

  @callback allowed_actions() :: [action()]

  @callback options :: options_mapping()

  alias Data.Events.RoomEntered
  alias Data.Events.RoomHeard

  @mapping %{
    "room/entered" => RoomEntered,
    "room/heard" => RoomHeard,
  }

  def mapping(), do: @mapping

  def parse(event) do
    with {:ok, event_type} <- find_type(event),
         {:ok, options} <- parse_options(event_type, event) do
      {:ok, struct(event_type, %{options: options, actions: []})}
    end
  end

  defp find_type(event) do
    case @mapping[event["type"]] do
      nil ->
        {:error, :no_type}

      event_type ->
        {:ok, event_type}
    end
  end

  defp parse_options(event_type, event) do
    with {:ok, options} <- Map.fetch(event, "options"),
         {:ok, options} <- validate_options(event_type, options) do
      {:ok, options}
    else
      :error ->
        {:ok, %{}}

      {:error, errors} ->
        {:error, :invalid_options, errors}
    end
  end

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

      iex> Events.valid_option_value?(:integer, 10)
      true
      iex> Events.valid_option_value?(:integer, "string")
      false

      iex> Events.valid_option_value?(:string, "string")
      true
      iex> Events.valid_option_value?(:string, 10)
      false

      iex> Events.valid_option_value?({:array, :string}, ["string"])
      true
      iex> Events.valid_option_value?({:array, :string}, ["string", 10])
      false
      iex> Events.valid_option_value?({:array, :string}, 10)
      false
  """
  def valid_option_value?(type, value) do
    case type do
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
