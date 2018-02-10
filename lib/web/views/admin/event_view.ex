defmodule Web.Admin.EventView do
  use Web, :view

  def action_template(%{type: "emote"}), do: "_action_emote.html"
  def action_template(%{type: "move"}), do: "_action_move.html"
  def action_template(%{type: "say"}), do: "_action_say.html"
  def action_template(%{type: "target/effects"}), do: "_action_target_effects.html"
  def action_template(%{type: "target"}), do: "_action_target.html"
end
