defmodule Game.Session.State do
  @moduledoc """
  Create a struct for Session state
  """

  alias Game.Session.SessionStats

  @type t :: %__MODULE__{}

  @doc """
  Session state storage

  - `:id` - a UUID for this connection
  - `:socket` - Socket process pid
  - `:state` - State of the session, `login`, `create`, `active`
  - `:mode` - Mode that the session is in, `commands`, `editor`
  - `:session_started_at` - Timestamp of when the session started
  - `:user` - User struct
  - `:character` - Character struct for the user
  - `:save` - Save struct from the user
  - `:last_recv` - Timestamp of when the session last received a message
  - `:idle` - Map of data required for idle checking and hinting
  - `:target` - Target of the user
  - `:is_targeting` - MapSet of who is targeting the user
  - `:regen` - Regen timestamps
  - `:reply_to` - User who the player should respond to
  - `:commands` - Temporary command storage, for continuing, editing, etc
  - `:skills` - Similar to `:commands`, but for skills (last used at)
  - `:is_afk` - Flag for if the user is AFK or not
  - `:continuous_effects` - Continuous effects that the user has, list
  - `:create` - storage for creating a character
  - `:login` - storage for logging in
  """
  @enforce_keys [:socket, :state, :mode]
  defstruct [
    :id,
    :socket,
    :state,
    :session_started_at,
    :user,
    :character,
    :save,
    :last_recv,
    :idle,
    :target,
    :is_targeting,
    :regen,
    :reply_to,
    :commands,
    :skills,
    :is_afk,
    :create,
    :login,
    mode: "comands",
    continuous_effects: [],
    stats: %SessionStats{}
  ]
end
