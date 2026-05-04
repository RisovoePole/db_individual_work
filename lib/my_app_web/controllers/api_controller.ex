defmodule MyAppWeb.ApiController do
  use MyAppWeb, :controller

  alias MyApp.Auth
  alias MyApp.Auth.User
  alias MyApp.Repo

  action_fallback MyAppWeb.FallbackController

  def get_user(conn, %{"id" => id}) do
    case Integer.parse(id) do
      {user_id, ""} ->
        case Auth.get_user_by_id(user_id) do
          nil -> {:error, :not_found}
          user -> json(conn, %{id: user.id, email: user.email})
        end

      _ ->
        {:error, :bad_request}
    end
  end

  def get_all_user(conn, _params) do
    users =
      Repo.all(User)
      |> Enum.map(fn user -> %{id: user.id, email: user.email} end)

    json(conn, %{users: users})
  end

  def login(conn, %{"email" => email, "password" => password}) do
    case Auth.authenticate_user(email, password) do
      {:ok, user} ->
        token = Auth.generate_token(user)
        :ok = Auth.store_token(token, user)

        json(conn, %{token: token, token_type: "Bearer"})

      {:error, :invalid_credentials} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "invalid_credentials"})
    end
  end

  def login(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "invalid_request"})
  end

  def hello(conn, _params) do
    current_user = conn.assigns.current_user
    json(conn, %{message: "Hello, #{current_user.email}"})
  end

  def logout(conn, _params) do
    token = bearer_token!(conn)
    :ok = Auth.revoke_token(token)
    conn |> send_resp(:no_content, "") |> halt()
  end

  defp bearer_token!(conn) do
    ["Bearer " <> token] = get_req_header(conn, "authorization")
    token
  end
end
