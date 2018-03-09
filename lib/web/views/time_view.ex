defmodule Web.TimeView do
  @timezone Application.get_env(:ex_venture, :timezone)

  def time(time) do
    new_york = Timex.Timezone.get(@timezone, Timex.now())

    time
    |> Timex.Timezone.convert(new_york)
    |> Timex.format!("%Y-%m-%d %I:%M %p", :strftime)
  end

  def relative(time) do
    Timex.format!(time, "{relative}", :relative)
  end
end
