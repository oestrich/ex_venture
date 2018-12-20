defmodule Game.Format.Mail do
  @moduledoc """
  Format functions for mail
  """

  import Game.Format.Context

  alias Data.Mail
  alias Game.Format
  alias Game.Format.Table

  @doc """
  Format mail for a player
  """
  @spec list_mail([Mail.t()]) :: String.t()
  def list_mail(mail) do
    rows =
      mail
      |> Enum.map(fn mail ->
        [to_string(mail.id), Format.player_name(mail.sender), mail.title]
      end)

    Table.format("You have #{length(mail)} unread mail.", rows, [5, 20, 30])
  end

  @doc """
  Format a single piece of mail for a player

      iex> Game.Format.display_mail(%{id: 1,sender: %{name: "Player"}, title: "hello", body: "A\\nlong message"})
      "1 - {player}Player{/player} - hello\\n----------------------\\n\\nA\\nlong message"
  """
  @spec display_mail(Mail.t()) :: String.t()
  def display_mail(mail) do
    context()
    |> assign(:title, title(mail))
    |> assign(:underline, Format.underline(title(mail)))
    |> assign(:body, mail.body)
    |> Format.template(template("mail"))
  end

  def title(mail) do
    context()
    |> assign(:id, mail.id)
    |> assign(:sender, Format.player_name(mail.sender))
    |> assign(:title, mail.title)
    |> Format.template(template("title"))
  end

  def template("title") do
    "[id] - [sender] - [title]"
  end

  def template("mail") do
    """
    [title]
    [underline]

    [body]
    """
  end
end
