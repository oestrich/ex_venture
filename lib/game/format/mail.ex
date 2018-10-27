defmodule Game.Format.Mail do
  @moduledoc """
  Format functions for mail
  """

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
    title = "#{mail.id} - #{Format.player_name(mail.sender)} - #{mail.title}"
    "#{title}\n#{Format.underline(title)}\n\n#{mail.body}"
  end
end
