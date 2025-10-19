{ stdenv, lib, fetchFromGitHub, autoPatchelfHook, makeWrapper, kernel }:

stdenv.mkDerivation rec {
  pname = "nvidia-340-updated";
  version = "340.108";

  src = fetchFromGitHub {
    owner = "dkosmari";
    repo = "nvidia-340.108-updated";
    rev = "b09fbaea3dee9a63cc9e3046437998576da7d07e";
    sha256 = "0000000000000000000000000000000000000000000000000000"; # Замените после первой сборки
  };

  nativeBuildInputs = [ autoPatchelfHook makeWrapper ];
  
  buildInputs = [ ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    mkdir -p $out
    echo "NVIDIA 340.108 updated package placeholder" > $out/README
  '';

  meta = with lib; {
    description = "Updated NVIDIA 340.108 driver with patches for newer kernels";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
  };
}