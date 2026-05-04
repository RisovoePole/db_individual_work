defmodule MyApp.Auth do
  import Ecto.Query

  alias MyApp.Auth.User
  alias MyApp.Redis
  alias MyApp.Repo

  @token_salt "user auth"
  @token_max_age_in_seconds 7 * 24 * 60 * 60
  @token_store_prefix "auth:token:"
  @token_blacklist_prefix "auth:blacklist:"

  def get_user_by_email(email) when is_binary(email) do
    Repo.one(from user in User, where: user.email == ^email)
  end

  def get_user_by_id(id) when is_integer(id) do
    Repo.get(User, id)
  end

  def authenticate_user(email, password)
      when is_binary(email) and is_binary(password) do
    case get_user_by_email(email) do
      %User{} = user ->
        if password_hash(password) == user.password_hash do
          {:ok, user}
        else
          {:error, :invalid_credentials}
        end

      nil ->
        {:error, :invalid_credentials}
    end
  end

  def generate_token(%User{id: id}) do
    Phoenix.Token.sign(MyAppWeb.Endpoint, @token_salt, id)
  end

  def store_token(token, %User{id: id}) when is_binary(token) and is_integer(id) do
    with {:ok, _} <-
           Redis.command([
             "SET",
             token_store_key(token),
             Integer.to_string(id),
             "EX",
             token_ttl()
           ]) do
      :ok
    end
  end

  def blacklist_token(token) when is_binary(token) do
    with {:ok, ttl} <- Redis.command(["TTL", token_store_key(token)]),
         ttl when is_integer(ttl) <- normalized_ttl(ttl) do
      write_blacklist(token, ttl)
    end
  end

  def revoke_token(token) when is_binary(token) do
    with {:ok, ttl} <- Redis.command(["TTL", token_store_key(token)]),
         ttl when is_integer(ttl) <- normalized_ttl(ttl),
         {:ok, _} <- Redis.command(["DEL", token_store_key(token)]),
         :ok <- write_blacklist(token, ttl) do
      :ok
    end
  end

  def verify_token(token) when is_binary(token) do
    with {:ok, user_id} <-
           Phoenix.Token.verify(
             MyAppWeb.Endpoint,
             @token_salt,
             token,
             max_age: @token_max_age_in_seconds
           ),
         true <- is_integer(user_id),
         true <- token_stored?(token, user_id),
         false <- token_blacklisted?(token),
         %User{} = user <- get_user_by_id(user_id) do
      {:ok, user}
    else
      _ -> {:error, :unauthorized}
    end
  end

  def token_stored?(token, user_id) when is_binary(token) and is_integer(user_id) do
    case Redis.command(["GET", token_store_key(token)]) do
      {:ok, user_id_as_string} when is_binary(user_id_as_string) ->
        user_id_as_string == Integer.to_string(user_id)

      {:ok, _} ->
        false

      _ ->
        false
    end
  end

  def token_blacklisted?(token) when is_binary(token) do
    case Redis.command(["EXISTS", token_blacklist_key(token)]) do
      {:ok, 1} -> true
      {:ok, 0} -> false
      _ -> true
    end
  end

  def password_hash(password) when is_binary(password) do
    :crypto.hash(:sha256, password)
    |> Base.encode16(case: :lower)
  end

  def token_store_key(token), do: @token_store_prefix <> token
  def token_blacklist_key(token), do: @token_blacklist_prefix <> token

  def token_ttl, do: Integer.to_string(@token_max_age_in_seconds)

  defp normalized_ttl(ttl) when ttl < 1, do: @token_max_age_in_seconds
  defp normalized_ttl(ttl) when is_integer(ttl) and ttl > 0, do: ttl

  defp write_blacklist(token, ttl) do
    with {:ok, _} <-
           Redis.command(["SET", token_blacklist_key(token), "1", "EX", Integer.to_string(ttl)]) do
      :ok
    end
  end
end
