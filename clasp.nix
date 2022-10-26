{ pkgs, ...}:


let

  src = pkgs.fetchFromGitHub {
    owner = "clasp-developers";
    repo = "clasp";
    rev = "2.0.0";
    hash = "sha256-McKEPnQ8PNm++KTvuEq6otpBp4oDvnPyS6NXI1Pi2Cg=";
  };

  reposDirs = [
    "dependencies"
    "src/lisp/kernel/contrib"
    "src/lisp/modules/asdf"
    "src/mps"
    "src/bdwgc"
    "src/libatomic_ops"
  ];

  reposTarball = pkgs.llvmPackages_14.stdenv.mkDerivation {
    pname = "clasp-repos";
    version = "tarball";
    inherit src;
    nativeBuildInputs = with pkgs; [
      sbcl
      git
      cacert
    ];
    buildPhase = ''
      export SOURCE_DATE_EPOCH=1
      export ASDF_OUTPUT_TRANSLATIONS=$(pwd):$(pwd)/__fasls
      sbcl --script koga --help
      for x in {${pkgs.lib.concatStringsSep "," reposDirs}}; do
        find $x -type d -name .git -exec rm -rvf {} \; || true
      done
    '';
    installPhase = ''
      tar --owner=0 --group=0 --numeric-owner --format=gnu \
        --sort=name --mtime="@$SOURCE_DATE_EPOCH" \
        -czf $out ${pkgs.lib.concatStringsSep " " reposDirs}
    '';
    outputHashMode = "flat";
    outputHashAlgo = "sha256";
    outputHash = "sha256-3q8l7+FNytEZYADSV6FWgsNKX15dUJ6C6kKE/Blefbc=";
  };

in pkgs.llvmPackages_14.stdenv.mkDerivation { 
  pname = "clasp";
  version = "2.0.0";  
  inherit src;
  nativeBuildInputs = (with pkgs; [
    sbcl
    git
    pkg-config
    fmt
    gmpxx
    libelf
    boost
    libunwind
    ninja
  ]) ++ (with pkgs.llvmPackages_14; [
    llvm
    libclang
  ]);
  configurePhase = ''
    export SOURCE_DATE_EPOCH=1
    export ASDF_OUTPUT_TRANSLATIONS=$(pwd):$(pwd)/__fasls
    tar xf ${reposTarball}
    sbcl --script koga \
      --skip-sync \
      --cc=$NIX_CC/bin/cc \
      --cxx=$NIX_CC/bin/c++ \
      --reproducible-build \
      --package-path=/ \
      --bin-path=$out/bin \
      --lib-path=$out/lib \
      --share-path=$out/share
  '';
  buildPhase = ''
    ninja -C build
  '';
  installPhase = ''
    ninja -C build install    
  '';
}
