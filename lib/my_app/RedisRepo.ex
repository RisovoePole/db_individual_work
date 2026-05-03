defmodule MyApp.Redis do
  def start_link(opts) do
    redis_url = Application.get_env(:my_app, :redis_url)
    Redix.start_link(redis_url, opts)
  end

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 5000
    }
  end
end
