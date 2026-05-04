defmodule MyAppWeb.ApiRouter do
  use Phoenix.Router

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/", MyAppWeb do
    pipe_through(:api)

    get("/users", ApiController, :get_all_user)
    get("/users/:id", ApiController, :get_user)
  end
end
