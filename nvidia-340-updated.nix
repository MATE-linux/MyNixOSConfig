{ stdenv, lib, fetchFromGitHub, autoPatchelfHook, makeWrapper, kernel, wget, curl, binutils, kmod }:

stdenv.mkDerivation rec {
  pname = "nvidia-340-updated";
  version = "340.108";

  src = fetchFromGitHub {
    owner = "dkosmari";
    repo = "nvidia-340.108-updated";
    rev = "a8f0fe0a30cade1ed4d31f8b2fca95e50f6f5444";
    sha256 = "2pahIWOSPb+i2yRX4Ev3VLXaYNnCZFmVPU4xP7mRkSQ=";
  };

  nativeBuildInputs = [ 
    autoPatchelfHook 
    makeWrapper 
    wget
    curl
    binutils
    kmod
  ];

  buildInputs = [ stdenv.cc.cc.lib ];

  dontConfigure = true;

  buildPhase = ''
    # Даем скриптам права на выполнение
    chmod +x apply-patch.sh
    
    # Запускаем скрипт, который сам скачает и пропатчит .run файл
    echo "Запуск apply-patch.sh для скачивания и патчинга драйвера..."
    ./apply-patch.sh

    # Проверяем что .run файл создался
    if [ ! -f "NVIDIA-Linux-x86_64-${version}.run" ]; then
      echo "Ошибка: Пропатченный .run файл не создался!"
      exit 1
    fi

    echo "Пропатченный .run файл готов: NVIDIA-Linux-x86_64-${version}.run"
  '';

  installPhase = ''
    # Собираем и устанавливаем модуль ядра через Makefile из репозитория
    echo "Сборка и установка модуля ядра..."
    make KVERSION="${kernel.modDirVersion}" SYSSRC="${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
    make KVERSION="${kernel.modDirVersion}" SYSSRC="${kernel.dev}/lib/modules/${kernel.modDirVersion}/build" INSTALL_MOD_PATH=$out modules_install

    # Устанавливаем пользовательскую часть из пропатченного .run файла
    echo "Установка пользовательской части драйвера..."
    chmod +x "NVIDIA-Linux-x86_64-${version}.run"
    "./NVIDIA-Linux-x86_64-${version}.run" --no-kernel-module --accept-license --no-questions --no-backup
    
    # Копируем установленные файлы в $out
    mkdir -p $out/bin $out/lib $out/share/nvidia
    
    # Копируем бинарные файлы
    find /usr/bin -name "nvidia-*" -maxdepth 1 -type f -exec cp {} $out/bin/ \; 2>/dev/null || true
    
    # Копируем библиотеки  
    cp -r /usr/lib64/* $out/lib/ 2>/dev/null || true
    cp -r /usr/lib/* $out/lib/ 2>/dev/null || true
    
    # Копируем данные
    cp -r /usr/share/nvidia/* $out/share/nvidia/ 2>/dev/null || true

    # Создаем обертки для основных утилит
    for bin in $out/bin/nvidia-settings $out/bin/nvidia-xconfig; do
      if [ -f "$bin" ]; then
        wrapProgram "$bin" \
          --prefix LD_LIBRARY_PATH : "$out/lib:${lib.makeLibraryPath buildInputs}"
      fi
    done
  '';

  postFixup = ''
    # Автоматически исправляем библиотечные зависимости
    autoPatchelf $out
  '';

  meta = with lib; {
    description = "Updated NVIDIA 340.108 driver with patches for newer kernels";
    homepage = "https://github.com/dkosmari/nvidia-340.108-updated";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
  };
}