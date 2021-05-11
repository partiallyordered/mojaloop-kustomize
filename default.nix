{ nixpkgs ? import (fetchTarball https://github.com/NixOS/nixpkgs/archive/8e4fe32876ca15e3d5eb3ecd3ca0b224417f5f17.tar.gz) { } }:

let kubefwd = nixpkgs.stdenv.mkDerivation rec {
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
  nixpkgs.kubeval
  nixpkgs.minikube
  nixpkgs.skaffold
  kubefwd
]
