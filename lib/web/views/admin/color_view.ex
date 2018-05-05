defmodule Web.Admin.ColorView do
  use Web, :view

  alias Game.Config

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

  def color_field(field, name) do
    field = :"color_#{field}"
    code = apply(Config, field, [])

    content_tag(:div, class: "form-group") do
      [
        label(:colors, field, name, class: "col-md-4"),
        content_tag(:div, class: "col-md-1") do
          color_preview(code)
        end,
        content_tag(:div, class: "col-md-7") do
          text_input(:colors, field, value: code, class: "form-control color-input")
        end
      ]
    end
  end

  def color_preview(code) do
    content_tag(:div, "", class: "color-preview", style: "background-color: #{code}")
  end
end
