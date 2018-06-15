defmodule Networking.GMCPTest do
  use ExUnit.Case

  alias Networking.GMCP

  describe "checking if the module message is OK to send" do
    test "module not in the supported list" do
      refute GMCP.message_allowed?(%{gmcp_supports: ["Core"]}, "Character.Info")
    end

    test "core is always allowed" do
      assert GMCP.message_allowed?(%{gmcp_supports: ["Character"]}, "Core.Heartbeat")
    end

    test "module in the supported list" do
      assert GMCP.message_allowed?(%{gmcp_supports: ["Character"]}, "Character.Info")
      assert GMCP.message_allowed?(%{gmcp_supports: ["Character"]}, "Character.Vitals")
    end

    test "with submodules" do
      assert GMCP.message_allowed?(%{gmcp_supports: ["External.Discord"]}, "External.Discord.Status")
    end
  end
end
