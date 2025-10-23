{
  description = "Explore Education Statistics Nix flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nodejs_18_17_0.url = "github:nixos/nixpkgs/4e6868b1aa3766ab1de169922bb3826143941973";
  };

  outputs = { self, nixpkgs, ... }@inputs:
  let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    aotDeps = [
      pkgs.zlib
      pkgs.zlib.dev
      pkgs.openssl
      #pkgs.dotnetCorePackages.sdk_6_0
      (with pkgs.dotnetCorePackages; combinePackages [
        sdk_6_0
      ])
    ];
  in
  {
    devShells.${system}.default =
      pkgs.mkShell
      {
        nativeBuildInputs = [
          pkgs.git
          inputs.nodejs_18_17_0.legacyPackages.${system}.nodejs_18
          inputs.nodejs_18_17_0.legacyPackages.${system}.nodejs_18.pkgs.pnpm

          pkgs.azure-functions-core-tools
          pkgs.docker
          pkgs.docker-compose
          pkgs.python310
          pkgs.pipenv

          pkgs.nix-ld
        ] ++ aotDeps ;

        shellHook = ''
          echo "EES flake active!"
        '';

        # env variables
        IdpConfig = "Keycloak";
        DOTNET_ROOT = "${pkgs.dotnetCorePackages.sdk_6_0}";
        NIX_LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath ([
          pkgs.stdenv.cc.cc
        ] ++ aotDeps);
        NIX_LD = "${pkgs.stdenv.cc.libc_bin}/bin/ld.so";
      };
  };
}
