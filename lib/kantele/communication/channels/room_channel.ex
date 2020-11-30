defmodule Kantele.RoomChannel do
  use Kalevala.Communication.Channel

  @impl true
  def subscribe_request(_channel_name, options, config) do
    case config[:room_id] == options[:character].room_id do
      true ->
        :ok

      false ->
        {:error, :not_in_room}
    end
  end

  @impl true
  def unsubscribe_request(_channel_name, options, config) do
    case config[:room_id] != options[:character].room_id do
      true ->
        :ok

      false ->
        {:error, :in_room}
    end
  end

  @impl true
  def publish_request(_channel_name, _event, options, config) do
    case config[:room_id] == options[:character].room_id do
      true ->
        :ok

      false ->
        {:error, :not_in_room}
    end
  end
end
