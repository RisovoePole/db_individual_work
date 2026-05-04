defmodule MyApp.AuthTest do
  use MyApp.DataCase, async: false

  alias MyApp.Auth
  alias MyApp.Auth.User
  alias MyApp.Repo

  setup do
    :ok = flush_redis()
    :ok
  end

  test "authenticate_user/2 returns user for valid credentials" do
    user =
      Repo.insert!(%User{
        email: "user@example.com",
        password_hash: Auth.password_hash("secret123")
      })

    user_id = user.id

    assert {:ok, %User{id: ^user_id}} = Auth.authenticate_user("user@example.com", "secret123")
  end

  test "verify_token/1 returns user for valid token" do
    user =
      Repo.insert!(%User{
        email: "token@example.com",
        password_hash: Auth.password_hash("secret123")
      })

    token = Auth.generate_token(user)
    :ok = Auth.store_token(token, user)

    user_id = user.id

    assert {:ok, %User{id: ^user_id}} = Auth.verify_token(token)
  end

  test "authenticate_user/2 returns invalid_credentials for unknown user" do
    assert {:error, :invalid_credentials} =
             Auth.authenticate_user("missing@example.com", "secret123")
  end

  test "verify_token/1 returns unauthorized for invalid token" do
    assert {:error, :unauthorized} = Auth.verify_token("bad-token")
  end

  test "store_token/2 writes token to redis" do
    user =
      Repo.insert!(%User{
        email: "store@example.com",
        password_hash: Auth.password_hash("secret123")
      })

    token = Auth.generate_token(user)
    assert :ok = Auth.store_token(token, user)
    assert {:ok, value} = MyApp.Redis.command(["GET", Auth.token_store_key(token)])
    assert value == Integer.to_string(user.id)
  end

  test "blacklist_token/1 writes blacklist entry" do
    user =
      Repo.insert!(%User{
        email: "blacklist@example.com",
        password_hash: Auth.password_hash("secret123")
      })

    token = Auth.generate_token(user)
    assert :ok = Auth.store_token(token, user)
    assert :ok = Auth.blacklist_token(token)
    assert Auth.token_blacklisted?(token)
  end

  test "revoke_token/1 deletes token from redis and blacklists it" do
    user =
      Repo.insert!(%User{
        email: "revoke@example.com",
        password_hash: Auth.password_hash("secret123")
      })

    token = Auth.generate_token(user)
    :ok = Auth.store_token(token, user)

    assert :ok = Auth.revoke_token(token)
    assert Auth.token_blacklisted?(token)
    assert {:ok, nil} = MyApp.Redis.command(["GET", Auth.token_store_key(token)])
  end

  test "verify_token/1 rejects blacklisted tokens" do
    user =
      Repo.insert!(%User{
        email: "revoked@example.com",
        password_hash: Auth.password_hash("secret123")
      })

    token = Auth.generate_token(user)
    :ok = Auth.store_token(token, user)
    :ok = Auth.blacklist_token(token)

    assert {:error, :unauthorized} = Auth.verify_token(token)
  end

  defp flush_redis do
    case MyApp.Redis.command(["FLUSHDB"]) do
      {:ok, _} -> :ok
      other -> other
    end
  end
end
