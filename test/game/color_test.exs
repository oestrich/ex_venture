defmodule Game.ColorTest do
  use ExUnit.Case
  doctest Game.Color

  import Game.Color, only: [format: 1]

  test "replaces multiple colors" do
    assert format("{black}word{/black} {blue}word{/blue}") == "\e[30mword\e[0m \e[34mword\e[0m"
  end

  test "replaces black" do
    assert format("{black}word{/black}") == "\e[30mword\e[0m"
  end

  test "replaces red" do
    assert format("{red}word{/red}") == "\e[31mword\e[0m"
  end

  test "replaces green" do
    assert format("{green}word{/green}") == "\e[32mword\e[0m"
  end

  test "replaces yellow" do
    assert format("{yellow}word{/yellow}") == "\e[33mword\e[0m"
  end

  test "replaces blue" do
    assert format("{blue}word{/blue}") == "\e[34mword\e[0m"
  end

  test "replaces magenta" do
    assert format("{magenta}word{/magenta}") == "\e[35mword\e[0m"
  end

  test "replaces cyan" do
    assert format("{cyan}word{/cyan}") == "\e[36mword\e[0m"
  end

  test "replaces white" do
    assert format("{white}word{/white}") == "\e[37mword\e[0m"
  end

  test "replaces map colors" do
    assert format("{map:blue}[ ]{/map:blue}") == "\e[38;5;26m[ ]\e[0m"
  end

  test "replaces map colors - dark green" do
    assert format("{map:dark-green}[ ]{/map:dark-green}") == "\e[38;5;22m[ ]\e[0m"
  end

  describe "statemachine" do
    test "replaces a color after another color is reset" do
      assert format("{green}hi there {white}command{/white} green again{/green}") ==
        "\e[32mhi there \e[37mcommand\e[32m green again\e[0m"
    end

    test "handles larger text" do
      text =
        """
        {blue}Player{/blue} is here. {yellow}Guard{/yellow} ({yellow}!{/yellow}) is idling around.
        Exits: {white}north{/white}, {white}south{/white}

        {blue}This is a more {cyan}complicated{/cyan} line than the other one {green}many colors{/green}{/blue}
        """

      expected =
        """
        \e[34mPlayer\e[0m is here. \e[33mGuard\e[0m (\e[33m!\e[0m) is idling around.
        Exits: \e[37mnorth\e[0m, \e[37msouth\e[0m

        \e[34mThis is a more \e[36mcomplicated\e[34m line than the other one \e[32mmany colors\e[34m\e[0m
        """

      assert format(text) == expected
    end

    test "resets the color if there is stack left" do
      assert format("{green}hi there {white}command{/white} green again") ==
        "\e[32mhi there \e[37mcommand\e[32m green again\e[0m"
    end
  end
end
