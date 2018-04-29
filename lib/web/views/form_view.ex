defmodule Web.FormView do
  use Web, :view

  @doc """
  Generate a text field, styled properly
  """
  def text_field(form, field, opts \\ [], dopts \\ []) do
    opts = Keyword.merge(opts, dopts)
    text_opts = Keyword.take(opts, [:value, :rows])

    content_tag(:div, class: "form-group") do
      [
        label(form, field, class: "col-md-4"),
        content_tag(:div, class: "col-md-8") do
          [
            text_input(form, field, Keyword.merge([class: "form-control"], text_opts)),
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

    label =
      case Keyword.get(opts, :label) do
        nil ->
          label(form, field, class: "col-md-4")

        text ->
          label(form, field, text, class: "col-md-4")
      end

    content_tag(:div, class: "form-group") do
      [
        label,
        content_tag(:div, class: "col-md-8") do
          [
            number_input(form, field, Keyword.merge([class: "form-control"], number_opts)),
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

    content_tag(:div, class: "form-group") do
      [
        label(form, field, class: "col-md-4"),
        content_tag(:div, class: "col-md-8") do
          [
            textarea(form, field, Keyword.merge([class: "form-control"], textarea_opts)),
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

    content_tag(:div, class: "checkbox") do
      content_tag(:div, class: "col-md-8 col-md-offset-4") do
        [
          label(form, field) do
            [checkbox(form, field), " ", opts[:label]]
          end,
          error_tag(form, field),
          Keyword.get(opts, :do, "")
        ]
      end
    end
  end
end
