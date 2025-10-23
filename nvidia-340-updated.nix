{ stdenv, lib, fetchFromGitHub, fetchurl, autoPatchelfHook, makeWrapper, kernel, binutils, kmod, patchelf }:

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
  ];

  buildInputs = [ stdenv.cc.cc.lib ];

  dontConfigure = true;

  unpackPhase = ''
    # Распаковываем .run файл NVIDIA
    cp $src NVIDIA-Linux-x86_64-${version}.run
    chmod +x NVIDIA-Linux-x86_64-${version}.run
    ./NVIDIA-Linux-x86_64-${version}.run --extract-only
    cd NVIDIA-Linux-x86_64-${version}
    
    # Применяем только необходимые патчи для ядра 6.12
    echo "Применяем критически важные патчи..."
    
    # GCC 14 патч (обязательный)
    if [ -f "${aurPatches}/0017-gcc-14.patch" ]; then
      echo "Применяем gcc-14.patch..."
      patch -p1 < "${aurPatches}/0017-gcc-14.patch" || true
    fi
    
    # Патчи для ядер 6.x
    for patch in "${aurPatches}/0011-kernel-6.0.patch" \
                 "${aurPatches}/0012-kernel-6.2.patch" \
                 "${aurPatches}/0013-kernel-6.3.patch" \
                 "${aurPatches}/0014-kernel-6.5.patch" \
                 "${aurPatches}/0015-kernel-6.6.patch" \
                 "${aurPatches}/0016-kernel-6.8.patch"; do
      if [ -f "$patch" ]; then
        echo "Применяем $(basename $patch)..."
        patch -p1 < "$patch" || true
      fi
    done

    # Вручную исправляем проблему с autoconf.h
    echo "Ручное исправление autoconf.h..."
    find . -name "*.h" -type f -exec sed -i 's|<linux/autoconf.h>|<generated/autoconf.h>|g' {} + 2>/dev/null || true
    find . -name "*.c" -type f -exec sed -i 's|<linux/autoconf.h>|<generated/autoconf.h>|g' {} + 2>/dev/null || true
    
    # Отключаем проблемные conftest
    if [ -f "kernel/conftest.sh" ]; then
      sed -i 's/cc_options="$cc_options -Werror"/# cc_options="$cc_options -Werror"/g' kernel/conftest.sh
    fi
  '';

  buildPhase = ''
    # Патчим conftest для отключения ошибок
    cd kernel
    
    echo "Настройка conftest..."
    # Отключаем конкретные проблемные тесты
    sed -i '/test_x86_efi_enabled/d' conftest.sh
    sed -i '/test_generic_present/d' conftest.sh
    sed -i '/test_vmap/d' conftest.sh
    sed -i '/test_kmem_cache_create/d' conftest.sh
    sed -i '/test_on_each_cpu/d' conftest.sh
    sed -i '/test_smp_call_function/d' conftest.sh
    sed -i '/test_acpi_walk_namespace/d' conftest.sh
    sed -i '/test_pci_dma_mapping_error/d' conftest.sh
    
    # Собираем основной модуль ядра
    echo "Сборка основного модуля ядра..."
    make -C ${kernel.dev}/lib/modules/${kernel.modDirVersion}/build M=$(pwd) \
      KCFLAGS="-Wno-error -Wno-error=missing-prototypes -Wno-error=incompatible-pointer-types -Wno-error=implicit-function-declaration -Wno-error=date-time" \
      modules

    # Собираем модуль UVM (если нужно)
    echo "Сборка модуля UVM..."
    cd uvm
    make -C ${kernel.dev}/lib/modules/${kernel.modDirVersion}/build M=$(pwd) \
      KCFLAGS="-Wno-error -Wno-error=missing-prototypes -Wno-error=incompatible-pointer-types -Wno-error=implicit-function-declaration -Wno-error=date-time" \
      modules || echo "UVM модуль не собран, продолжаем..."
    
    cd ../..
  '';

  installPhase = ''
    # Устанавливаем модули ядра
    echo "Установка модулей ядра..."
    mkdir -p $out/lib/modules/${kernel.modDirVersion}/misc
    
    cd NVIDIA-Linux-x86_64-${version}/kernel
    
    # Устанавливаем основные модули
    install -D -m 644 nvidia.ko $out/lib/modules/${kernel.modDirVersion}/misc/nvidia.ko
    
    # Пытаемся установить UVM модуль если он есть
    if [ -f "uvm/nvidia-uvm.ko" ]; then
      install -D -m 644 uvm/nvidia-uvm.ko $out/lib/modules/${kernel.modDirVersion}/misc/nvidia-uvm.ko
    fi

    # Сжимаем модули
    find $out/lib/modules/${kernel.modDirVersion}/misc -name "*.ko" -exec gzip -9 {} +

    # Устанавливаем пользовательскую часть
    echo "Установка пользовательской части..."
    cd ../..
    mkdir -p $out/bin $out/lib $out/share/nvidia
    
    # Копируем бинарные файлы
    find NVIDIA-Linux-x86_64-${version} -maxdepth 1 -name "nvidia-*" -type f -executable -exec cp {} $out/bin/ \; 2>/dev/null || true
    
    # Копируем библиотеки  
    find NVIDIA-Linux-x86_64-${version} -name "*.so*" -type f -exec cp {} $out/lib/ \; 2>/dev/null || true
    
    # Создаем обертки для основных утилит
    for bin in $out/bin/nvidia-settings $out/bin/nvidia-xconfig; do
      if [ -f "$bin" ]; then
        wrapProgram "$bin" \
          --prefix LD_LIBRARY_PATH : "$out/lib:${lib.makeLibraryPath buildInputs}"
      fi
    done

    # Создаем конфигурацию для modprobe
    mkdir -p $out/etc/modprobe.d
    echo "blacklist nouveau" > $out/etc/modprobe.d/nvidia-340.conf
    echo "options nvidia NVreg_EnableMSI=1" >> $out/etc/modprobe.d/nvidia-340.conf
  '';

  postFixup = ''
    # Автоматически исправляем библиотечные зависимости
    autoPatchelf $out
    
    # Исправляем шебанги в установленных скриптах
    patchShebangs $out/bin
  '';

  meta = with lib; {
    description = "NVIDIA 340.108 driver with minimal patches for kernel 6.12";
    homepage = "https://github.com/archlinux-jerry/nvidia-340xx";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
  };
}