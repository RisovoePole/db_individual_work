defmodule MyAppWeb.ApiRouter do
  use Phoenix.Router

  require Apical

  Apical.router_from_file(
    "priv/openapi/api.yaml",
    controller: MyAppWeb.ApiController,
    root: "/"
  )
end
