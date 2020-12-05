defmodule Kantele.Config do
  @moduledoc """
  Game configuration for Kantele
  """

  use GenServer

  def get() do
    GenServer.call(__MODULE__, :get)
  end

  def get(key) do
    GenServer.call(__MODULE__, {:get, key})
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  def init(_) do
    {:ok, :not_loaded, {:continue, :load}}
  end

  def handle_continue(:load, _state) do
    {:noreply, Elias.parse(File.read!("data/config.ucl"))}
  end

  def handle_call(:get, _from, state), do: {:reply, state, state}

  def handle_call({:get, key}, _from, state), do: {:reply, get_in(state, key), state}
end
