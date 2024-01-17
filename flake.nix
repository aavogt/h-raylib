{
  inputs = {
    nixpkgs.url = "nixpkgs";
  };

  outputs = { self, nixpkgs, ... }@inputs:
    let
      supportedSystems = [ "x86_64-linux" ];
      forAllSystems' = nixpkgs.lib.genAttrs;
      forAllSystems = forAllSystems' supportedSystems;

      pkgsForSystem =
        system:
        import nixpkgs { 
          inherit system; 
          overlays = [  
            (self: super: {
              raylib = super.raylib.overrideAttrs (old: {
                patches = [];
                src = self.fetchFromGitHub {
                  owner = "raysan5";
                  repo = "raylib";
                  rev = "c57b8d5a6abbf210fece6b44dcdadd112a7e072e";
                  sha256 = "sha256-wByQ+8jBSp9r2Z4Ocv1H1KDEpsyvebPkHQvZabDJXS0=";
                };
                postFixup = ''
                  cp ../src/*.h $out/include/
                '';
              });
            })
          ]; 
        };
    in
      {
        devShells = forAllSystems (system:
          let
            pkgs = pkgsForSystem system;
          in
            {
              default =
                pkgs.mkShell rec {
                  LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath buildInputs;
                  buildInputs = with pkgs; [
                    stdenv.cc
                    ghc

                    glfw
                    cabal-install
                    xorg.libXinerama
                    xorg.libXcursor
                    xorg.libXrandr
                    xorg.libXi
                    xorg.libXext
                    raylib
                  ];
                };
            }
        );
        packages = forAllSystems (system: let
          pkgs = pkgsForSystem system;
        in {
          default = import ./default.nix (pkgs // pkgs.xorg // pkgs.haskellPackages);
        });
      };
}