defmodule Web.ColorCodeTest do
  use Data.ModelCase

  alias Web.ColorCode

  test "creating a code" do
    params = %{key: "orange", ansi_escape: "\\e[38;2;255;69;0;m", hex_code: "#FF4500"}

    {:ok, color_code} = ColorCode.create(params)

    assert ColorCode.latest_version() == Timex.to_unix(color_code.updated_at)
  end

  test "updating a code" do
    params = %{key: "orange", ansi_escape: "\\e[38;2;255;69;0;m", hex_code: "#FF4500"}

    {:ok, color_code} = ColorCode.create(params)
    {:ok, color_code} = ColorCode.update(color_code.id, %{hex_code: "#FF4511"})

    assert ColorCode.latest_version() == Timex.to_unix(color_code.updated_at)
  end
end
