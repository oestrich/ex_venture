defmodule Game.PGNotifications do
  @moduledoc """
  Subscriber to the PG pubsub for table changes

  For the game caching layer
  """

  use GenServer

  alias Data.Config
  alias Data.Item
  alias Game.Config, as: GameConfig
  alias Game.Items

  def start_link(opts) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  def init(_) do
    {:ok, %{}, {:continue, :connect}}
  end

  def handle_continue(:connect, state) do
    with {:ok, pid, ref} <- listen("row_changed") do
      state =
        state
        |> Map.put(:pg_pid, pid)
        |> Map.put(:pg_ref, ref)

      {:noreply, state}
    else
      error ->
        {:stop, error, state}
    end
  end

  def handle_info({:notification, _pid, _ref, "row_changed", payload}, state) do
    with {:ok, data} <- Jason.decode(payload) do
      update_local_cache(data)

      {:noreply, state}
    else
      error ->
        {:stop, error, state}
    end
  end

  defp update_local_cache(%{"table" => "items", "record" => item}) do
    item
    |> map_to_struct(Item)
    |> Items.reload()
  end

  defp update_local_cache(%{"table" => "config", "record" => config}) do
    config
    |> map_to_struct(Config)
    |> GameConfig.reload()
  end

  defp update_local_cache(_unknown), do: :ok

  defp map_to_struct(map, schema) do
    fields = Enum.map(schema.__schema__(:fields), &to_string/1)

    map =
      map
      |> Map.take(fields)
      |> Enum.into(%{}, fn {key, val} ->
        {String.to_atom(key), val}
      end)

    struct(schema, map)
  end

  defp listen(event_name) do
    opts =
      Keyword.take(Application.get_env(:ex_venture, Data.Repo), [
        :username,
        :database,
        :hostname,
        :port,
        :password
      ])

    with {:ok, pid} <- Postgrex.Notifications.start_link(opts),
         {:ok, ref} <- Postgrex.Notifications.listen(pid, event_name) do
      {:ok, pid, ref}
    end
  end
end
