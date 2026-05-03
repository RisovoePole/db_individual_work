defmodule MyAppWeb.ApiController do
  use Phoenix.Controller

  def hello(conn, _params) do
    json(conn, %{message: "Hello from Apical"})
  end
end
