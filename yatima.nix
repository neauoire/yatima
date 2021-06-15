# import niv sources and the pinned nixpkgs
{ sources ? import ./nix/sources.nix
, pkgs ? import sources.nixpkgs { overlays = [ (import ./nix/rust-overlay.nix) ]; }
, target ? null
  # import rust compiler
, rust ? import ./nix/rust.nix {
    inherit pkgs;
  }
  # configure naersk to use our pinned rust compiler
, naersk ? pkgs.callPackage sources.naersk {
    rustc = rust;
    cargo = rust;
  }
}:
with builtins;
let
  # tell nix-build to ignore the `target` directory
  project = builtins.filterSource
    (path: type: type != "directory" || builtins.baseNameOf path != "target")
    ./.;
in
naersk.buildPackage {
  name = "yatima";
  version = "0.1.0";
  buildInputs = with pkgs; [ openssl pkg-config ];
  PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig";
  targets = if target then [ target ] else [ ];
  src = "${project}";
  remapPathPrefix =
    true; # remove nix store references for a smaller output package
}
