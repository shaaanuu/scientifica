{
  description = "Scientifica: tall and condensed bitmap font for geeks";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  };
  outputs =
    {self, nixpkgs, ...}:
    let
      supportedSystems = [ "x86_64-linux" "x86_64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      nixpkgsFor = forAllSystems (system:
        import nixpkgs {
          inherit system;
          overlays = [ self.overlay ];
        });
    in
    {
      overlay = final: prev: rec {
        bitsnpicas = final.stdenvNoCC.mkDerivation {
          pname = "bitsnpicas";
          version = "2.0.2";
          
          src = final.fetchurl {
            url = "https://github.com/kreativekorp/bitsnpicas/releases/download/v2.0.2/BitsNPicas.jar";
            sha256 = "sha256-wJFIo2N6+Rk3COuh6QZw0d5IRNE19v273FR7MXeF6Ts=";
          };
          
          nativeBuildInputs = [ final.makeWrapper ];
          
          dontUnpack = true;
          
          installPhase = ''
            runHook preInstall
            mkdir -p $out/share/java $out/bin
            cp $src $out/share/java/BitsNPicas.jar
            makeWrapper ${final.jdk}/bin/java $out/bin/bitsnpicas \
              --add-flags "-jar $out/share/java/BitsNPicas.jar"
            runHook postInstall
          '';
        };
        
        scientifica = final.stdenvNoCC.mkDerivation {
          pname = "scientifica";
          version = "v2.3";
          src = ./src;
          nativeBuildInputs = [ final.fontforge bitsnpicas ];
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
          installPhase = ''
            runHook preInstall
            runHook postInstall
          '';
        };
      };
      packages = forAllSystems (system: {
        inherit (nixpkgsFor."${system}") scientifica bitsnpicas;
      });
      defaultPackage = forAllSystems (system: self.packages."${system}".scientifica);
    };
}
