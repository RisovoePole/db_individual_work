docker_build:
    nix build .#docker
    docker load < result
    arion up -d


init_submodules:
    cp .env.example .env
    git submodule update --init --recursive
