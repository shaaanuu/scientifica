{
  description = "Scientifica: tall and condensed bitmap font for geeks";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  };
  outputs = { self, nixpkgs, ... }:
    let
      supportedSystems = [ "x86_64-linux" "x86_64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      nixpkgsFor = forAllSystems (system:
        import nixpkgs {
          inherit system;
          overlays = [ self.overlay ];
        });
      bitsnpicasJar = builtins.fetchurl {
        url = "https://github.com/kreativekorp/bitsnpicas/releases/download/v2.1/BitsNPicas.jar";
        sha256 = "sha256:0iw5v8235vkl21r2qlbxcw0w6p7ii6s6fjnj6l0dq0n4hm70skmk";
      };
    in {
      overlay = final: prev: {
        bitsnpicas = final.writeScriptBin "bitsnpicas" ''
          exec ${final.jdk}/bin/java -jar ${bitsnpicasJar} "$@"
        '';
        scientifica = final.stdenvNoCC.mkDerivation {
          pname = "scientifica";
          version = "v2.4";
          src = ./src;
          nativeBuildInputs = [ final.fontforge final.bitsnpicas ];
          buildPhase = ''
            runHook preBuild
            ff_filter() {
              fontforge -c 'open(argv[1]).generate(argv[2])' "$@"
            }
            ttf_filter() {
              bitsnpicas convertbitmap -f ttf -o "$2" "$1"
            }
            mkdir -p $out/{ttf,otb,bdf}
            pushd $src
            # generate font files
            for i in *; do
              local file_name
              file_name="''${i%.*}"
              ttf_filter "$i" "$out/ttf/$file_name.ttf"
              ff_filter "$i" "$out/otb/$file_name.otb"
              ff_filter "$i" "$out/bdf/$file_name.bdf"
            done
            popd
            runHook postBuild
          '';
          installPhase = "true";
        };
      };
      packages = forAllSystems (system: {
        inherit (nixpkgsFor.${system}) scientifica bitsnpicas;
      });
      defaultPackage = forAllSystems (system: self.packages.${system}.scientifica);
    };
}
