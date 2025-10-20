{ stdenv, lib, fetchFromGitHub, fetchurl, autoPatchelfHook, makeWrapper, kernel, wget, curl, binutils, kmod, patch }:

stdenv.mkDerivation rec {
  pname = "nvidia-340-updated";
  version = "340.108";

  src = fetchFromGitHub {
    owner = "dkosmari";
    repo = "nvidia-340.108-updated";
    rev = "a8f0fe0a30cade1ed4d31f8b2fca95e50f6f5444";
    sha256 = "2pahIWOSPb+i2yRX4Ev3VLXaYNnCZFmVPU4xP7mRkSQ=";
  };
  
  # Предварительно скачиваем .run файл через fetchurl
  nvidiaRun = fetchurl {
    url = "https://us.download.nvidia.com/XFree86/Linux-x86_64/340.108/NVIDIA-Linux-x86_64-340.108.run";
    sha256 = "2pahIWOSPb+i2yRX4Ev3VLXaYNnCZFmVPU4xP7mRkSQ="; # Замени на актуальный хеш
  };

  nativeBuildInputs = [ 
    autoPatchelfHook 
    makeWrapper 
    wget
    curl
    binutils
    kmod
    patch
  ];

  buildInputs = [ stdenv.cc.cc.lib ];

  dontConfigure = true;

  buildPhase = ''
    # Используем встроенную функцию Nix для патчинга шебангов
    echo "Патчим шебанги скриптов..."
    patchShebangs .

    # Проверяем что шебанги исправлены
    echo "Проверяем apply-patch.sh:"
    head -1 apply-patch.sh
    echo "Проверяем generate-patch.sh:"
    head -1 generate-patch.sh

    # Запускаем скрипт, который сам скачает и пропатчит .run файл
    echo "Запуск apply-patch.sh для скачивания и патчинга драйвера..."
    ./apply-patch.sh

    # Проверяем что .run файл создался
    if [ ! -f "NVIDIA-Linux-x86_64-${version}.run" ]; then
      echo "Ошибка: Пропатченный .run файл не создался!"
      ls -la
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
    
    # Создаем временную директорию для установки
    mkdir -p nvidia-install
    cd nvidia-install
    
    # Распаковываем .run файл
    "../NVIDIA-Linux-x86_64-${version}.run" --extract-only
    
    # Копируем файлы в $out
    mkdir -p $out/bin $out/lib $out/share/nvidia
    
    # Копируем бинарные файлы
    find . -name "nvidia-*" -type f -executable -exec cp {} $out/bin/ \; 2>/dev/null || true
    
    # Копируем библиотеки  
    find . -name "*.so*" -type f -exec cp {} $out/lib/ \; 2>/dev/null || true
    
    # Копируем данные
    find . -path "*/share/nvidia/*" -type f -exec cp --parents {} $out/ \; 2>/dev/null || true

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
    
    # Исправляем шебанги в установленных скриптах
    patchShebangs $out/bin
  '';

  meta = with lib; {
    description = "Updated NVIDIA 340.108 driver with patches for newer kernels";
    homepage = "https://github.com/dkosmari/nvidia-340.108-updated";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
  };
}