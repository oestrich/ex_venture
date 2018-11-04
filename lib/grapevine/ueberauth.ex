defmodule Grapevine.Ueberauth.Strategy do
  @moduledoc """
  Grapevine authentication strategy for Ueberauth
  """

  use Ueberauth.Strategy, default_scope: "profile email"

  alias Grapevine.Ueberauth.Strategy.OAuth

  defmodule OAuth do
    @moduledoc """
    OAuth client used by the Grapevine Ueberauth strategy
    """

    use OAuth2.Strategy

    @defaults [
      strategy: __MODULE__,
      site: "https://grapevine.haus",
      authorize_url: "/oauth/authorize",
      token_url: "/oauth/token"
    ]

    def client(opts \\ []) do
      client_id = Application.get_env(:gossip, :client_id)
      client_secret = Application.get_env(:gossip, :client_secret)

      opts = Enum.reject(opts, fn {_key, val} -> is_nil(val) end)

      opts =
        @defaults
        |> Keyword.merge(opts)
        |> Keyword.merge([client_id: client_id, client_secret: client_secret])

      OAuth2.Client.new(opts)
    end

    def authorize_url!(params \\ [], opts \\ []) do
      opts
      |> client()
      |> OAuth2.Client.authorize_url!(params)
    end

    def get(token, url, opts \\ []) do
      [token: token]
      |> Keyword.merge(opts)
      |> client()
      |> OAuth2.Client.get(url)
    end

    def get_access_token(params \\ [], opts \\ []) do
      case opts |> client() |> OAuth2.Client.get_token(params) do
        {:error, %{body: %{"error" => error, "error_description" => description}}} ->
          {:error, {error, description}}

        {:ok, %{token: %{access_token: nil} = token}} ->
          %{"error" => error, "error_description" => description} = token.other_params
          {:error, {error, description}}

        {:ok, %{token: token}} ->
          {:ok, token}
      end
    end

    # Strategy Callbacks

    def authorize_url(client, params) do
      OAuth2.Strategy.AuthCode.authorize_url(client, params)
    end

    def get_token(client, params, headers) do
      client
      |> put_header("Accept", "application/json")
      |> put_header("Content-Type", "application/json")
      |> OAuth2.Strategy.AuthCode.get_token(params, headers)
    end
  end

  @impl true
  def handle_request!(conn) do
    scopes = Keyword.get(options(conn), :scope, Keyword.get(default_options(), :default_scope))

    params = [scope: scopes, state: UUID.uuid4()]
    opts = [site: site(conn), redirect_uri: callback_url(conn)]

    redirect!(conn, OAuth.authorize_url!(params, opts))
  end

  @impl true
  def handle_callback!(conn = %Plug.Conn{params: %{"code" => code}}) do
    params = [code: code]
    opts = [site: site(conn), redirect_uri: callback_url(conn)]

    case OAuth.get_access_token(params, opts) do
      {:ok, token} ->
        fetch_user(conn, token)

      {:error, {error_code, error_description}} ->
        set_errors!(conn, [error(error_code, error_description)])
    end
  end

  def handle_callback!(conn = %Plug.Conn{params: %{"error" => "access_denied"}}) do
    set_errors!(conn, [error("OAuth2", "Access was denied")])
  end

  def handle_callback!(conn) do
    set_errors!(conn, [error("OAuth2", "Failure to authenticate")])
  end

  @impl true
  def credentials(conn) do
    token = conn.private.grapevine_token

    %Ueberauth.Auth.Credentials{
      expires: true,
      expires_at: token.expires_at,
      refresh_token: token.refresh_token,
      token: token.access_token
    }
  end

  @impl true
  def uid(conn) do
    conn.private.grapevine_user["uid"]
  end

  @impl true
  def info(conn) do
    %Ueberauth.Auth.Info{
      email: conn.private.grapevine_user["email"],
      name: conn.private.grapevine_user["username"],
    }
  end

  defp fetch_user(conn, token) do
    conn = put_private(conn, :grapevine_token, token)

    opts = [site: site(conn)]
    response = OAuth.get(token, "/users/me", opts)

    case response do
      {:ok, %OAuth2.Response{status_code: 401, body: _body}} ->
        set_errors!(conn, [error("token", "unauthorized")])

      {:ok, %OAuth2.Response{status_code: 200, body: user}} ->
        put_private(conn, :grapevine_user, user)

      {:error, %OAuth2.Response{status_code: status_code}} ->
        set_errors!(conn, [error("OAuth2", status_code)])

      {:error, %OAuth2.Error{reason: reason}} ->
        set_errors!(conn, [error("OAuth2", reason)])
    end
  end

  defp site(conn), do: Keyword.get(options(conn), :site)
end
