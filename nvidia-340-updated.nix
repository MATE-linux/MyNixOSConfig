{ stdenv, lib, fetchFromGitHub, fetchurl, autoPatchelfHook, makeWrapper, kernel, binutils, kmod, patchelf }:

let
  version = "340.108";
  
  # Официальный драйвер от NVIDIA
  nvidiaRun = fetchurl {
    url = "https://us.download.nvidia.com/XFree86/Linux-x86_64/${version}/NVIDIA-Linux-x86_64-${version}.run";
    sha256 = "xnHU8bfAm8GvB5uYtEetsG1wSwT4AvcEWmEfpQEztxs=";
  };

  # Все патчи из AUR репозитория
  aurPatches = fetchFromGitHub {
    owner = "archlinux-jerry";
    repo = "nvidia-340xx";
    rev = "main"; # Используем последний коммит
    sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # Замени на реальный хеш
  };

  # Список патчей в правильном порядке применения
  patchList = [
    "0001-kernel-5.7.patch"
    "0002-kernel-5.8.patch" 
    "0003-kernel-5.9.patch"
    "0004-kernel-5.10.patch"
    "0005-kernel-5.11.patch"
    "0006-kernel-5.14.patch"
    "0007-kernel-5.15.patch"
    "0008-kernel-5.16.patch"
    "0009-kernel-5.17.patch"
    "0010-kernel-5.18.patch"
    "0011-kernel-6.0.patch"
    "0012-kernel-6.2.patch"
    "0013-kernel-6.3.patch"
    "0014-kernel-6.5.patch"
    "0015-kernel-6.6.patch"
    "0016-kernel-6.8.patch"
    "0017-gcc-14.patch"
    "0018-gcc-15.patch"
    "0019-kernel-6.15.patch"
  ];

in stdenv.mkDerivation rec {
  pname = "nvidia-340-aur-patched";
  inherit version;

  src = nvidiaRun;

  nativeBuildInputs = [ 
    autoPatchelfHook 
    makeWrapper 
    binutils
    kmod
    patchelf
  ];

  buildInputs = [ stdenv.cc.cc.lib ];

  dontConfigure = true;

  unpackPhase = ''
    # Распаковываем .run файл NVIDIA
    cp $src NVIDIA-Linux-x86_64-${version}.run
    chmod +x NVIDIA-Linux-x86_64-${version}.run
    ./NVIDIA-Linux-x86_64-${version}.run --extract-only
    cd NVIDIA-Linux-x86_64-${version}
    
    # Применяем все патчи из AUR в правильном порядке
    echo "Применяем патчи из AUR..."
    ${lib.concatMapStrings (patch: ''
      echo "Применяем ${patch}..."
      patch -p1 < "${aurPatches}/${patch}"
    '') patchList}
  '';

  buildPhase = ''
    # Собираем основной модуль ядра
    echo "Сборка основного модуля ядра..."
    cd kernel
    make -C ${kernel.dev}/lib/modules/${kernel.modDirVersion}/build M=$(pwd) \
      KCFLAGS="-Wno-error=missing-prototypes -Wno-error=incompatible-pointer-types -Wno-error" \
      modules

    # Собираем модуль UVM
    echo "Сборка модуля UVM..."
    cd uvm
    make -C ${kernel.dev}/lib/modules/${kernel.modDirVersion}/build M=$(pwd) \
      KCFLAGS="-Wno-error=missing-prototypes -Wno-error=incompatible-pointer-types -Wno-error" \
      modules
    cd ../..
  '';

  installPhase = ''
    # Устанавливаем модули ядра
    echo "Установка модулей ядра..."
    mkdir -p $out/lib/modules/${kernel.modDirVersion}/kernel/drivers/video/nvidia
    cd NVIDIA-Linux-x86_64-${version}/kernel
    
    install -m 0644 nvidia.ko $out/lib/modules/${kernel.modDirVersion}/kernel/drivers/video/nvidia/
    install -m 0644 uvm/nvidia-uvm.ko $out/lib/modules/${kernel.modDirVersion}/kernel/drivers/video/nvidia/

    # Сжимаем модули
    find $out/lib/modules/${kernel.modDirVersion}/kernel/drivers/video/nvidia -name "*.ko" -exec gzip -9 {} +

    # Устанавливаем пользовательскую часть
    echo "Установка пользовательской части..."
    cd ../..
    mkdir -p $out/bin $out/lib $out/share/nvidia
    
    # Копируем бинарные файлы
    find NVIDIA-Linux-x86_64-${version} -name "nvidia-*" -type f -executable -exec cp {} $out/bin/ \; 2>/dev/null || true
    
    # Копируем библиотеки  
    find NVIDIA-Linux-x86_64-${version} -name "*.so*" -type f -exec cp {} $out/lib/ \; 2>/dev/null || true
    
    # Копируем данные
    find NVIDIA-Linux-x86_64-${version} -path "*/share/nvidia/*" -type f -exec cp --parents {} $out/ \; 2>/dev/null || true

    # Копируем конфигурацию Xorg
    mkdir -p $out/share/X11/xorg.conf.d
    cp ${aurPatches}/20-nvidia.conf $out/share/X11/xorg.conf.d/20-nvidia.conf

    # Создаем обертки для основных утилит
    for bin in $out/bin/nvidia-settings $out/bin/nvidia-xconfig; do
      if [ -f "$bin" ]; then
        wrapProgram "$bin" \
          --prefix LD_LIBRARY_PATH : "$out/lib:${lib.makeLibraryPath buildInputs}"
      fi
    done
  '';

  postInstall = ''
    # Создаем ссылки для модулей ядра
    mkdir -p $out/lib/modules/${kernel.modDirVersion}/extra
    ln -s $out/lib/modules/${kernel.modDirVersion}/kernel/drivers/video/nvidia $out/lib/modules/${kernel.modDirVersion}/extra/nvidia
  '';

  postFixup = ''
    # Автоматически исправляем библиотечные зависимости
    autoPatchelf $out
    
    # Исправляем шебанги в установленных скриптах
    patchShebangs $out/bin
  '';

  meta = with lib; {
    description = "NVIDIA 340.108 driver with AUR patches for kernel 6.12+";
    homepage = "https://github.com/archlinux-jerry/nvidia-340xx";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
  };
}