defmodule Web.ReactView do
  use Web, :view

  @doc """
  Generate a react component tag
  """
  def react_component(name, props) do
    props = Poison.encode!(Enum.into(props, %{}))
    content_tag(:div, "", [{:data, [react_class: name, react_props: props]}])
  end
end
