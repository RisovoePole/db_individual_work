defmodule MyAppWeb.Router do
  use MyAppWeb, :router

  alias MyAppWeb.Plugs.RequireAuth

  pipeline :api do
    plug(:accepts, ["json"])
  end

  pipeline :api_auth do
    plug(:accepts, ["json"])
    plug(RequireAuth)
  end

  scope "/api", MyAppWeb do
    pipe_through(:api)

    post "/auth/login", ApiController, :login
  end

  scope "/api", MyAppWeb do
    pipe_through(:api_auth)

    get "/hello", ApiController, :hello
    post "/auth/logout", ApiController, :logout
  end

  scope "/api" do
    forward("/", MyAppWeb.ApiRouter)
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:my_app, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through([:fetch_session, :protect_from_forgery])

      live_dashboard("/dashboard", metrics: MyAppWeb.Telemetry)
      forward("/mailbox", Plug.Swoosh.MailboxPreview)
    end
  end
end
