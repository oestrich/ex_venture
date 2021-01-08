defmodule Web.ReactView do
  use Web, :view

  @doc """
  Generate a react component tag
  """
  def react_component(name, props, opts \\ []) do
    props = Jason.encode!(Enum.into(props, %{}))
    opts = Keyword.merge(opts, [{:data, [react_class: name, react_props: props]}])
    content_tag(:div, "", opts)
  end
end
