{ nixpkgs ? import (fetchTarball https://github.com/NixOS/nixpkgs/archive/8e4fe32876ca15e3d5eb3ecd3ca0b224417f5f17.tar.gz) { } }:

let
  k3d = nixpkgs.stdenv.mkDerivation rec {
    version = "4.4.1";
    pname = "k3d";

    src = builtins.fetchurl {
      url = "https://github.com/rancher/k3d/releases/download/v4.4.1/k3d-linux-amd64";
      sha256 = "1bjmyhf0zbi6lfq71h6vazmlkxg0b46wky5vqv1dqbkr2bdr2s24";
    };

    dontUnpack = true;

    installPhase = ''
      mkdir -p $out/bin
      cp $src $out/bin/k3d
      chmod +x $out/bin/k3d
    '';

    dontFixup = true;
  };

  kubefwd = nixpkgs.stdenv.mkDerivation rec {
    version = "1.18.1";
    pname = "kubefwd";

    src = builtins.fetchurl {
      url = "https://github.com/txn2/kubefwd/releases/download/${version}/kubefwd_Linux_x86_64.tar.gz";
      sha256 = "1864jayfczlyliz6h7gybrjrfnyabshc0kpbxvavp6ni9r6pm489";
    };

    unpackPhase = ''
      tar xf $src
    '';

    installPhase = ''
        install -m755 -D kubefwd $out/bin/kubefwd
    '';
  };

in


[
  nixpkgs.kustomize
  nixpkgs.kubectl
  nixpkgs.kubeval
  nixpkgs.skaffold
  kubefwd
  k3d
]
