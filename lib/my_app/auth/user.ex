defmodule MyApp.Auth.User do
  use Ecto.Schema

  schema "users" do
    field :email, :string
    field :password_hash, :string
  end
end
