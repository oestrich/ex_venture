defmodule Web.Endpoint do
  use Phoenix.Endpoint, otp_app: :ex_venture

  socket("/socket", Web.CharacterSocket)
  socket("/admin/socket", Web.AdminSocket)

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phoenix.digest
  # when deploying your static files in production.
  plug(
    Plug.Static,
    at: "/",
    from: :ex_venture,
    gzip: true,
    only: ~w(css fonts images js favicon.ico robots.txt)
  )

  if code_reloading? do
    plug(Phoenix.CodeReloader)
  end

  # Add some CORS
  plug CORSPlug, origin: ["*"]

  plug(Plug.RequestId)
  plug(Logster.Plugs.Logger)
  plug(:set_logger_metadata)

  plug(
    Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Poison
  )

  plug(Plug.MethodOverride)
  plug(Plug.Head)

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  plug(
    Plug.Session,
    store: :cookie,
    max_age: 24 * 60 * 60 * 31,
    key: "_ex_venture_key",
    signing_salt: "dJUOZQux"
  )

  plug(Web.PrometheusExporter)
  plug(Metrics.PipelineInstrumenter)

  plug(Web.Router)

  @doc """
  Callback invoked for dynamically configuring the endpoint.

  It receives the endpoint configuration and checks if
  configuration should be loaded from the system environment.
  """
  def init(_key, config) do
    if config[:load_from_system_env] do
      port = System.get_env("PORT") || raise "expected the PORT environment variable to be set"
      {:ok, Keyword.put(config, :http, [:inet6, port: port])}
    else
      {:ok, config}
    end
  end

  def set_logger_metadata(conn, _opts) do
    Logger.metadata(type: :phoenix)
    conn
  end
end
