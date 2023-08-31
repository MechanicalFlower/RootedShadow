{ lib
, stdenv
, rustPlatform
, llvmPackages
, buildInputs
}:

let
  cargoToml = (builtins.fromTOML (builtins.readFile ./addons/native-impl/Cargo.toml));
in
rustPlatform.buildRustPackage rec {
  pname = cargoToml.package.name;
  version = cargoToml.package.version;

  src = ./.;
  cargoLock = {
    lockFile = ./Cargo.lock;
  };

  preBuild = ''
    # From: https://github.com/NixOS/nixpkgs/blob/1fab95f5190d087e66a3502481e34e15d62090aa/pkgs/applications/networking/browsers/firefox/common.nix#L247-L253
    # Set C flags for Rust's bindgen program. Unlike ordinary C
    # compilation, bindgen does not invoke $CC directly. Instead it
    # uses LLVM's libclang. To make sure all necessary flags are
    # included we need to look in a few places.
    export BINDGEN_EXTRA_CLANG_ARGS="$(< ${stdenv.cc}/nix-support/libc-crt1-cflags) \
      $(< ${stdenv.cc}/nix-support/libc-cflags) \
      $(< ${stdenv.cc}/nix-support/cc-cflags) \
      $(< ${stdenv.cc}/nix-support/libcxx-cxxflags) \
      ${lib.optionalString stdenv.cc.isClang "-idirafter ${stdenv.cc.cc}/lib/clang/${lib.getVersion stdenv.cc.cc}/include"} \
      ${lib.optionalString stdenv.cc.isGNU "-isystem ${stdenv.cc.cc}/include/c++/${lib.getVersion stdenv.cc.cc} -isystem ${stdenv.cc.cc}/include/c++/${lib.getVersion stdenv.cc.cc}/${stdenv.hostPlatform.config} -idirafter ${stdenv.cc.cc}/lib/gcc/${stdenv.hostPlatform.config}/${lib.getVersion stdenv.cc.cc}/include"} \
    "
  '';

  buildPhase = ''
    cargo build --release --target wasm32-unknown-unknown
  '';
  installPhase = ''
    mkdir -p $out/lib
    cp target/wasm32-unknown-unknown/release/*.wasm $out/lib/
  '';

  # Point bindgen to where the clang library would be
  LIBCLANG_PATH = "${llvmPackages.libclang.lib}/lib";

  nativeBuildInputs = buildInputs;
  # nativeBuildInputs = [ darwin.apple_sdk.frameworks.Security darwin.apple_sdk.frameworks.CoreFoundation darwin.apple_sdk.frameworks.CoreServices ];

  meta = with lib; {
    description = cargoToml.package.description;
    homepage = cargoToml.package.homepage;
    license = with licenses; [ mit ];
  };
}
