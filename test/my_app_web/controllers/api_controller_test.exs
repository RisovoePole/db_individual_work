defmodule MyAppWeb.ApiControllerTest do
  use MyAppWeb.ConnCase, async: false

  alias MyApp.Auth
  alias MyApp.Auth.User
  alias MyApp.Repo

  setup do
    :ok = flush_redis()
    :ok
  end

  test "POST /api/auth/login returns token for valid credentials", %{conn: conn} do
    user =
      Repo.insert!(%User{
        email: "admin",
        password_hash: Auth.password_hash("admin123")
      })

    conn = post(conn, "/api/auth/login", %{email: "admin", password: "admin123"})

    assert %{"token" => token, "token_type" => "Bearer"} = json_response(conn, 200)
    assert is_binary(token)
    assert {:ok, value} = MyApp.Redis.command(["GET", Auth.token_store_key(token)])
    assert value == Integer.to_string(user.id)
  end

  test "POST /api/auth/login returns 401 for invalid credentials", %{conn: conn} do
    Repo.insert!(%User{
      email: "admin",
      password_hash: Auth.password_hash("admin123")
    })

    conn = post(conn, "/api/auth/login", %{email: "admin", password: "bad"})

    assert %{"error" => "invalid_credentials"} = json_response(conn, 401)
  end

  test "GET /api/hello returns 401 without token", %{conn: conn} do
    conn = get(conn, "/api/hello")

    assert %{"error" => "unauthorized"} = json_response(conn, 401)
  end

  test "GET /api/hello returns 401 with invalid token", %{conn: conn} do
    conn =
      conn
      |> put_req_header("authorization", "Bearer bad-token")
      |> get("/api/hello")

    assert %{"error" => "unauthorized"} = json_response(conn, 401)
  end

  test "GET /api/hello returns 200 with valid token", %{conn: conn} do
    user =
      Repo.insert!(%User{
        email: "admin",
        password_hash: Auth.password_hash("admin123")
      })

    token = Auth.generate_token(user)
    :ok = Auth.store_token(token, user)

    conn =
      conn
      |> put_req_header("authorization", "Bearer " <> token)
      |> get("/api/hello")

    assert %{"message" => "Hello, admin"} = json_response(conn, 200)
  end

  test "POST /api/auth/logout blacklists the token", %{conn: conn} do
    user =
      Repo.insert!(%User{
        email: "admin",
        password_hash: Auth.password_hash("admin123")
      })

    token = Auth.generate_token(user)
    :ok = Auth.store_token(token, user)

    conn =
      conn
      |> put_req_header("authorization", "Bearer " <> token)
      |> post("/api/auth/logout")

    assert response(conn, 204)
    assert Auth.token_blacklisted?(token)
    assert {:ok, nil} = MyApp.Redis.command(["GET", Auth.token_store_key(token)])
  end

  test "GET /api/hello returns 401 after logout", %{conn: conn} do
    user =
      Repo.insert!(%User{
        email: "admin",
        password_hash: Auth.password_hash("admin123")
      })

    token = Auth.generate_token(user)
    :ok = Auth.store_token(token, user)

    conn =
      conn
      |> put_req_header("authorization", "Bearer " <> token)
      |> post("/api/auth/logout")

    assert response(conn, 204)

    conn = Phoenix.ConnTest.build_conn()

    conn =
      conn
      |> put_req_header("authorization", "Bearer " <> token)
      |> get("/api/hello")

    assert %{"error" => "unauthorized"} = json_response(conn, 401)
  end

  defp flush_redis do
    case MyApp.Redis.command(["FLUSHDB"]) do
      {:ok, _} -> :ok
      other -> other
    end
  end
end
