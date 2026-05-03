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
      # environment = {
      #   DATABASE_URL = "''${DATABASE_URL}";
      #   REDIS_URL = "''${REDIS_URL}";
      #   SECRET_KEY_BASE = "''${SECRET_KEY_BASE}";
      # };

    env_file = [ "./.env" ];
      depends_on = ["postgres" "redis"];
    };

    postgres.service = {
      image = "postgres:16";
      # environment = {
      #   POSTGRES_USER = "''${POSTGRES_USER}";
      #   POSTGRES_PASSWORD = "''${POSTGRES_PASSWORD}";
      #   POSTGRES_DB = "''${POSTGRES_DB}";
      # };

    env_file = [ "./.env" ];
      volumes = ["postgres_data:/var/lib/postgresql/data"];
    };

    redis.service = {
      image = "redis:7-alpine";
      # environment = {
      #   REDIS_PASSWORD = "''${REDIS_PASSWORD}";
      # };

    env_file = [ "./.env" ];
      volumes = ["redis_data:/data"];
    };
  };
}