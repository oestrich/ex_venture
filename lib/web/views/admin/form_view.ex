defmodule Web.Admin.FormView do
  use Web, :view

  @doc """
  Label helper to optionally override the label text
  """
  def field_label(form, field, opts) do
    case Keyword.get(opts, :label) do
      nil ->
        label(form, field, class: "label")

      text ->
        label(form, field, text, class: "label")
    end
  end

  @doc """
  Generate a text field, styled properly
  """
  def text_field(form, field, opts \\ [], dopts \\ []) do
    opts = Keyword.merge(opts, dopts)
    text_opts = Keyword.take(opts, [:type, :value, :autofocus])

    content_tag(:div, class: form_group_classes(form, field)) do
      [
        field_label(form, field, opts),
        content_tag(:div, class: "flex flex-col w-full") do
          [
            text_input(form, field, Keyword.merge([class: "input"], text_opts)),
            error_tag(form, field),
            Keyword.get(opts, :do, "")
          ]
        end
      ]
    end
  end

  @doc """
  Generate a text field, styled properly
  """
  def password_field(form, field, opts \\ [], dopts \\ []) do
    opts = Keyword.merge(opts, dopts)
    text_opts = Keyword.take(opts, [:value, :rows])

    content_tag(:div, class: form_group_classes(form, field)) do
      [
        field_label(form, field, opts),
        content_tag(:div, class: "flex flex-col w-full") do
          [
            password_input(form, field, Keyword.merge([class: "input"], text_opts)),
            error_tag(form, field),
            Keyword.get(opts, :do, "")
          ]
        end
      ]
    end
  end

  @doc """
  Generate a number field, styled properly
  """
  def number_field(form, field, opts \\ [], dopts \\ []) do
    opts = Keyword.merge(opts, dopts)
    number_opts = Keyword.take(opts, [:placeholder, :min, :max])

    content_tag(:div, class: form_group_classes(form, field)) do
      [
        field_label(form, field, opts),
        content_tag(:div, class: "flex flex-col w-full") do
          [
            number_input(form, field, Keyword.merge([class: "input"], number_opts)),
            error_tag(form, field),
            Keyword.get(opts, :do, "")
          ]
        end
      ]
    end
  end

  @doc """
  Generate a textarea field, styled properly
  """
  def textarea_field(form, field, opts \\ [], dopts \\ []) do
    opts = Keyword.merge(opts, dopts)
    textarea_opts = Keyword.take(opts, [:value, :rows])

    content_tag(:div, class: form_group_classes(form, field)) do
      [
        field_label(form, field, opts),
        content_tag(:div, class: "flex flex-col w-full") do
          [
            textarea(form, field, Keyword.merge([class: "input"], textarea_opts)),
            error_tag(form, field),
            Keyword.get(opts, :do, "")
          ]
        end
      ]
    end
  end

  @doc """
  Generate a checkbox field, styled properly
  """
  def checkbox_field(form, field, opts \\ [], dopts \\ []) do
    opts = Keyword.merge(opts, dopts)

    content_tag(:div, class: "input-group") do
      [
        content_tag(:div, ""),
        content_tag(:div) do
          [
            label(form, field, class: "label font-bold") do
              [checkbox(form, field), " ", opts[:label]]
            end,
            error_tag(form, field),
            Keyword.get(opts, :do, "")
          ]
        end
      ]
    end
  end

  defp form_group_classes(form, field) do
    case Keyword.has_key?(form.errors, field) do
      true ->
        "input-group error"

      false ->
        "input-group"
    end
  end
end
