defmodule Web.ColorView do
  use Web, :view

  def render("codes.css", %{color_codes: color_codes}) do
    color_codes
    |> Enum.map(fn color_code ->
      """
      .color-code-#{color_code.key} {
        color: #{color_code.hex_code};
      }
      """
    end)
    |> Enum.join("\n")
  end
end
