{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    nixpkgs.inputs.nixpkgs.follows = "nixpkgs";

    flake-utils.url = "github:numtide/flake-utils/11707dc2f618dd54ca8739b309ec4fc024de578b";
  };

  outputs =
    { nixpkgs, flake-utils, ... }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
    in
    flake-utils.lib.eachSystem systems (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        packages = rec {
          thin-container = pkgs.dockerTools.buildImage rec {
            name = "nyarla/nix-thin-container";
            tag = "v2024.11.1";

            copyToRoot = pkgs.buildEnv {
              inherit name;

              paths = with pkgs; [
                busybox
                cacert
                fakeNss
              ];

              pathsToLink = [
                "/bin"
                "/etc"
              ];

              postBuild = ''
                mkdir -p $out/tmp
                mkdir -p $out/var/lib/app
                mkdir -p $out/data
              '';
            };

            config = {
              Env = [
                "PATH=/bin"
                "NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt"
              ];
              WorkingDir = "/var/lib/app";
              Volumes = {
                "/data" = { };
              };
              Entrypoint = [ "/bin/sh" ];
            };
          };

          default = thin-container;
        };
      }
    );
}
