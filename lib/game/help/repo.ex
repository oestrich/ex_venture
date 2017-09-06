defmodule Game.Help.Repo do
  @moduledoc """
  Repo helper for HelpTopics
  """

  alias Data.HelpTopic
  alias Data.Repo

  def all() do
    HelpTopic
    |> Repo.all
  end
end
