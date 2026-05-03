{
  description = "No-add";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs { inherit system; };
    beam = pkgs.beam.packages.erlang_27;
    src = pkgs.lib.cleanSource ./.;

    mixFodDeps = beam.fetchMixDeps {
      inherit src;
      pname = "my_app";
      version = "0.1.0";
      hash = "sha256-Yqs5BIQT8Z/jcxNPQPAcgKA/21V/RGaPsPbCc815U9Y=";
    };

    backend = beam.mixRelease {
      inherit src mixFodDeps;
      pname = "my_app";
      version = "0.1.0";
      mixEnv = "prod";
      mixReleaseName = "my_app";
      removeCookie = true;
    };

    dockerImage = pkgs.dockerTools.buildLayeredImage {
      name = "elixir-backend";
      tag = "latest";
      contents = [ backend ];
      config = {
        Cmd = [ "${backend}/bin/my_app" "start" ];
        Env = [
          "RELEASE_DISTRIBUTION=none"
          "RELEASE_COOKIE=my_app_cookie"
          "LANG=en_US.UTF-8"      
          "LC_ALL=en_US.UTF-8" 
        ];
      };
    };

  in {
    packages.${system}.docker = dockerImage;
  };
}