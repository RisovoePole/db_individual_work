build:
    nix build .#docker
    docker load < result
    arion up -d

init:
    cp .env.example .env
    git submodule update --init --recursive
