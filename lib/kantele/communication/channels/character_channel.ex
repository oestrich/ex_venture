defmodule Kantele.CharacterChannel do
  use Kalevala.Communication.Channel

  @impl true
  def subscribe_request(_channel_name, options, config) do
    case config[:character_id] == options[:character].id do
      true ->
        :ok

      false ->
        {:error, :not_allowed}
    end
  end

  @impl true
  def unsubscribe_request(_channel_name, options, config) do
    case config[:character_id] == options[:character].id do
      true ->
        :ok

      false ->
        {:error, :not_allowed}
    end
  end

  @impl true
  def publish_request(_channel_name, _event, options, config) do
    case config[:character_id] == options[:character].id do
      true ->
        {:error, :yourself}

      false ->
        :ok
    end
  end
end
