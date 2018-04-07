defmodule Web.Admin.ColorCodeView do
  use Web, :view

  def console_codes(conn, color_codes) do
    color_codes
    |> Enum.map(fn color_code ->
      [
        content_tag(:span, color_code.key, class: "color-code-#{color_code.key}"),
        " ",
        link("Edit", to: color_code_path(conn, :edit, color_code.id)),
        "\n"
      ]
    end)
  end
end
