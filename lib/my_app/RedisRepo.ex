defmodule MyApp.Redis do
  def start_link(opts) do
    redis_url = Application.get_env(:my_app, :redis_url)
    Redix.start_link(redis_url, Keyword.put_new(opts, :name, __MODULE__))
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

  def command(command) do
    Redix.command(__MODULE__, command)
  end

  def pipeline(commands) do
    Redix.pipeline(__MODULE__, commands)
  end
end
