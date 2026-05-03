{
  project.name = "my-app";

  docker-compose.volumes = {
      postgres_data = {};
      redis_data = {};
    };

  services = {
    backend.service = {
      image = "elixir-backend:latest";
      ports = ["4000:4000"];
      env_file = [ "./.env" ];
      depends_on = ["postgres" "redis"];
    };

    postgres.service = {
      image = "postgres:16";
      env_file = [ "./.env" ];
      volumes = ["postgres_data:/var/lib/postgresql/data"];
    };

    redis.service = {
      image = "redis:7-alpine";
      env_file = [ "./.env" ];
      volumes = ["redis_data:/data"];
    };
  };
}