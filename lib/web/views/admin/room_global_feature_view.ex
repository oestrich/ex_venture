defmodule Web.Admin.RoomGlobalFeatureView do
  use Web, :view

  def feature_options(features) do
    Enum.map(features, fn feature ->
      label = "#{feature.key} - #{Enum.join(feature.tags, ", ")}"

      {label, feature.id}
    end)
  end
end
