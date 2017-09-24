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
end
