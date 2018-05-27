defmodule ErrorReport do
  @moduledoc """
  Error reporting to an external service
  """

  @report_errors Application.get_env(:ex_venture, :errors)[:report]

  @doc """
  Report an error to the external service
  """
  @spec send_error(String.t()) :: :ok
  def send_error(message) do
    case @report_errors do
      true ->
        Sentry.capture_message(message)

      false ->
        :ok
    end
  end
end
