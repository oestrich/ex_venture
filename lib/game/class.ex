defmodule Game.Class do
  @moduledoc """
  A behaviour for classes.
  """

  import Ecto.Query

  alias Data.Class
  alias Data.Repo

  @callback run() :: :ok

  @doc """
  List of classes
  """
  @spec classes() :: [Data.Class.t]
  def classes() do
    Class
    |> preload([:skills])
    |> Repo.all
  end

  def compile_classes() do
    classes()
    |> Enum.each(fn (class) ->
      class.skills
      |> Enum.each(fn (skill) ->
        module = """
        defmodule Game.Class.#{class.module_name}.#{skill.module_name} do
          @behaviour Game.Class

          #{skill.code}
        end
        """
        Code.compile_string(module)
      end)
    end)
  end
end
