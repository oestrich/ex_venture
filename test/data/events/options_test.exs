defmodule Data.Events.OptionsTest do
  use ExUnit.Case

  alias Data.Events
  alias Data.Events.Options

  doctest Options

  describe "validating options" do
    test "empty options" do
      {:ok, %{}} = Options.validate_options(Events.RoomHeard, %{})
    end

    test "verifying type is correct" do
      {:ok, %{regex: "string"}} = Options.validate_options(Events.RoomHeard, %{"regex" => "string"})
    end

    test "extra keys are ignored" do
      {:ok, %{}} = Options.validate_options(Events.RoomHeard, %{"extra" => "string"})
    end

    test "wrong type options returns an error" do
      {:error, %{regex: "invalid"}} = Options.validate_options(Events.RoomHeard, %{"regex" => 10})
    end
  end
end
