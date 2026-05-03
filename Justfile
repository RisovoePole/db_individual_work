docker_build:
    nix build .#docker
    docker load < result
    arion up -d


init_submodules:
    git submodule update --init --recursive