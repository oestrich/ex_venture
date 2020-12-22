defmodule Web.API.Link do
  @moduledoc false

  @derive Jason.Encoder
  defstruct [:href, :rel]
end
