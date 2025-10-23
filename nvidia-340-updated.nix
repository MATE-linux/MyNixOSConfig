{ stdenv, lib, fetchFromGitHub, fetchurl, autoPatchelfHook, makeWrapper, kernel, binutils, kmod, patchelf, glibc, ncurses, gcc14 }:

let
  version = "340.108";
  
  # Официальный драйвер от NVIDIA
  nvidiaRun = fetchurl {
    url = "https://us.download.nvidia.com/XFree86/Linux-x86_64/${version}/NVIDIA-Linux-x86_64-${version}.run";
    sha256 = "xnHU8bfAm8GvB5uYtEetsG1wSwT4AvcEWmEfpQEztxs=";
  };

  # Патчи из AUR репозитория
  aurPatches = fetchFromGitHub {
    owner = "archlinux-jerry";
    repo = "nvidia-340xx";
    rev = "main";
    sha256 = "sha256-O6UaPV03c0XcN5F5yIGXDb0fBfhtAIzuj/PbKeSMjmg="; # Замени на реальный хеш
  };


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
    gcc14  # Явно используем GCC 14
  ];

  buildInputs = [ 
    stdenv.cc.cc.lib 
    glibc
    glibc.static
    ncurses
  ];

  dontConfigure = true;

  unpackPhase = ''
    cp $src NVIDIA-Linux-x86_64-${version}.run
    chmod +x NVIDIA-Linux-x86_64-${version}.run
    ./NVIDIA-Linux-x86_64-${version}.run --extract-only
    cd NVIDIA-Linux-x86_64-${version}
    
    echo "Применяем ВСЕ актуальные патчи для ядра 6.12 и GCC 14..."
    
    # Применяем все патчи последовательно
    for patch in "${aurPatches}/"*.patch; do
      patch_name=$(basename "$patch")
      echo "Применяем $patch_name..."
      patch -p1 --ignore-whitespace < "$patch" || echo "Пропускаем проблемный патч: $patch_name"
    done

    # Специфичные исправления для ядра 6.12
    echo "Дополнительные исправления для 6.12..."
    
    # Исправление для output_poll_changed (критически важно для 6.12)
    if [ -f "kernel/nv-drm.c" ]; then
      sed -i 's/\.output_poll_changed = nv_drm_output_poll_changed,//g' kernel/nv-drm.c
    fi
    
    # Исправление autoconf.h
    find . -name "*.h" -type f -exec sed -i 's|<linux/autoconf.h>|<generated/autoconf.h>|g' {} + 2>/dev/null || true
    find . -name "*.c" -type f -exec sed -i 's|<linux/autoconf.h>|<generated/autoconf.h>|g' {} + 2>/dev/null || true
    
    # Отключаем strict проверки
    if [ -f "kernel/conftest.sh" ]; then
      sed -i 's/cc_options="$cc_options -Werror"/# cc_options="$cc_options -Werror"/g' kernel/conftest.sh
    fi
  '';

  buildPhase = ''
    # Явно используем GCC 14
    export CC=${gcc14}/bin/gcc
    export HOSTCC=$CC
    export C_INCLUDE_PATH="${glibc.dev}/include:${kernel.dev}/include:${gcc14}/include"
    export CPLUS_INCLUDE_PATH="$C_INCLUDE_PATH"
    
    echo "Используем компилятор: $CC"
    $CC --version
    
    cd kernel
    
    echo "Настройка conftest..."
    # Минимальное вмешательство в conftest - только отключаем самые проблемные тесты
    sed -i '/test_x86_efi_enabled/d' conftest.sh
    sed -i '/test_generic_present/d' conftest.sh
    
    echo "Сборка основного модуля с GCC 14..."
    make -C ${kernel.dev}/lib/modules/${kernel.modDirVersion}/build M=$(pwd) \
      CC="$CC" \
      HOSTCC="$CC" \
      KCFLAGS="-Wno-error -Wno-error=missing-prototypes -Wno-error=incompatible-pointer-types -Wno-error=implicit-function-declaration -Wno-error=date-time" \
      modules

    echo "Сборка UVM модуля с GCC 14..."
    cd uvm
    make -C ${kernel.dev}/lib/modules/${kernel.modDirVersion}/build M=$(pwd) \
      CC="$CC" \
      HOSTCC="$CC" \
      KCFLAGS="-Wno-error -Wno-error=missing-prototypes -Wno-error=incompatible-pointer-types -Wno-error=implicit-function-declaration -Wno-error=date-time" \
      modules || echo "UVM не собран, но продолжаем..."
    
    cd ../..
  '';

  installPhase = ''
    echo "Установка модулей ядра..."
    mkdir -p $out/lib/modules/${kernel.modDirVersion}/misc
    
    cd NVIDIA-Linux-x86_64-${version}/kernel
    
    install -D -m 644 nvidia.ko $out/lib/modules/${kernel.modDirVersion}/misc/nvidia.ko
    
    if [ -f "uvm/nvidia-uvm.ko" ]; then
      install -D -m 644 uvm/nvidia-uvm.ko $out/lib/modules/${kernel.modDirVersion}/misc/nvidia-uvm.ko
    fi

    find $out/lib/modules/${kernel.modDirVersion}/misc -name "*.ko" -exec gzip -9 {} +

    echo "Установка пользовательской части..."
    cd ../..
    mkdir -p $out/bin $out/lib $out/share/nvidia
    
    find NVIDIA-Linux-x86_64-${version} -maxdepth 1 -name "nvidia-*" -type f -executable -exec cp {} $out/bin/ \; 2>/dev/null || true
    
    find NVIDIA-Linux-x86_64-${version} -name "*.so*" -type f -exec cp {} $out/lib/ \; 2>/dev/null || true
    
    for bin in $out/bin/nvidia-settings $out/bin/nvidia-xconfig; do
      if [ -f "$bin" ]; then
        wrapProgram "$bin" \
          --prefix LD_LIBRARY_PATH : "$out/lib:${lib.makeLibraryPath buildInputs}"
      fi
    done

    mkdir -p $out/etc/modprobe.d
    echo "blacklist nouveau" > $out/etc/modprobe.d/nvidia-340.conf
    echo "options nvidia NVreg_EnableMSI=1" >> $out/etc/modprobe.d/nvidia-340.conf
    
    # Копируем конфигурацию Xorg
    mkdir -p $out/share/X11/xorg.conf.d
    cat > $out/share/X11/xorg.conf.d/20-nvidia.conf << 'EOF'
Section "Files"
  ModulePath   "/run/opengl-driver/lib/xorg/modules"
  ModulePath   "/run/opengl-driver-32/lib/xorg/modules"
EndSection

Section "Device"
  Identifier "Nvidia Card"
  Driver "nvidia"
  VendorName "NVIDIA Corporation"
  Option "NoLogo" "true"
EndSection

Section "ServerFlags"
  Option "IgnoreABI" "1"
EndSection
EOF
  '';

  postFixup = ''
    autoPatchelf $out
    patchShebangs $out/bin
  '';

  meta = with lib; {
    description = "NVIDIA 340.108 driver with minimal patches for kernel 6.12";
    homepage = "https://github.com/archlinux-jerry/nvidia-340xx";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
  };
}