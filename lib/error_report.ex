defmodule ErrorReport do
  @report_errors Application.get_env(:ex_venture, :errors)[:report]

  def send_error(message) do
    case @report_errors do
      true ->
        Sentry.capture_message(message)

      false ->
        :ok
    end
  end
end
