defmodule Game.Command.SocialsTest do
  use Data.ModelCase
  import Test.SocialsHelper

  doctest Game.Command.Socials

  alias Data.Social
  alias Game.Command.Socials

  @socket Test.Networking.Socket

  setup do
    @socket.clear_messages()
    start_and_clear_socials()

    user = create_user(%{name: "user", password: "password"})
    %{state: %{socket: :socket, user: user}}
  end

  describe "list out all socials" do
    setup do
      %Social{id: 1, name: "Smile", command: "smile"} |> insert_social()
      %Social{id: 2, name: "Laugh", command: "laugh"} |> insert_social()
      :ok
    end

    test "a paginated response", %{state: state} do
      {:paginate, echo, _state} = Socials.run({:list}, state)

      assert Regex.match?(~r/Smile/, echo)
    end
  end

  describe "view a single social" do
    setup do
      %Social{id: 1, name: "Smile", command: "smile"} |> insert_social()
      %Social{id: 2, name: "Laugh", command: "laugh"} |> insert_social()
      :ok
    end

    test "social is found", %{state: state} do
      :ok = Socials.run({:help, "smile"}, state)

      [{_socket, echo}] = @socket.get_echos()
      assert Regex.match?(~r/Smile/, echo)
    end

    test "social is not found", %{state: state} do
      :ok = Socials.run({:help, "wave"}, state)

      [{_socket, echo}] = @socket.get_echos()
      assert Regex.match?(~r/could not be found/, echo)
    end
  end
end
