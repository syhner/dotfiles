# Hex's published Linux release, repackaged. Building it from source compiles
# over 400 Rust crates, which takes about twenty minutes, and no binary cache
# has it. The libraries and programs it finds at run time are the ones the
# hex flake's own package (nix/package.nix) gives it.
{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  autoAddDriverRunpath,
  makeWrapper,
  symlinkJoin,
  alsa-lib,
  alsa-plugins,
  curl,
  ffmpeg-headless,
  fontconfig,
  libva,
  libx11,
  libxcb,
  libxcursor,
  libxi,
  libxkbcommon,
  libxrandr,
  openblas,
  openssl,
  pipewire,
  vulkan-loader,
  wayland,
  wl-clipboard,
  wtype,
}:
let
  version = "3.3.0";

  sources = {
    x86_64-linux = {
      arch = "x64";
      hash = "sha256-5bNnju0zygfIdxUI9Y34ajRva3EyQ2buk9IF6KbVRFA=";
    };
    aarch64-linux = {
      arch = "arm64";
      hash = "sha256-diSWLpKHdRfOsfY1ogRnR0XvV5imVOxfvkrmZlXb/hk=";
    };
  };
  source =
    sources.${stdenv.hostPlatform.system}
      or (throw "hex-bin doesn't support ${stdenv.hostPlatform.system}");

  # Opened while it runs rather than linked.
  runtimeLibraries = [
    alsa-lib
    fontconfig
    libva
    libx11
    libxcb
    libxcursor
    libxi
    libxkbcommon
    libxrandr
    openblas
    pipewire
    vulkan-loader
    wayland
  ];

  alsaPlugins = symlinkJoin {
    name = "hex-alsa-plugins";
    paths = [
      "${pipewire}/lib/alsa-lib"
      "${alsa-plugins}/lib/alsa-lib"
    ];
  };
in
stdenv.mkDerivation {
  pname = "hex-bin";
  inherit version;

  src = fetchurl {
    url = "https://github.com/anomalyco/hex/releases/download/v${version}/hex-${version}-linux-${source.arch}.deb";
    inherit (source) hash;
  };

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    autoAddDriverRunpath
    makeWrapper
  ];

  # What the binary links.
  buildInputs = [
    alsa-lib
    libxkbcommon
    openssl
    stdenv.cc.cc.lib
    vulkan-loader
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r usr/bin usr/share $out/
    substituteInPlace $out/share/applications/anomaly.hex.desktop \
      --replace-fail /usr/bin/hex $out/bin/hex

    runHook postInstall
  '';

  postFixup = ''
    wrapProgram $out/bin/hex \
      --prefix PATH : ${
        lib.makeBinPath [
          curl
          ffmpeg-headless
          wl-clipboard
          wtype
        ]
      } \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath runtimeLibraries} \
      --set ALSA_PLUGIN_DIR ${alsaPlugins}
  '';

  meta = {
    description = "Local voice dictation (official Linux release)";
    homepage = "https://anoma.ly/hex/";
    license = lib.licenses.mit;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    mainProgram = "hex";
    platforms = builtins.attrNames sources;
  };
}
