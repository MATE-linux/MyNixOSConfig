{ stdenv, lib, fetchFromGitHub, autoPatchelfHook, makeWrapper, kernel, wget, gnused, gnugrep, patchelf }:

stdenv.mkDerivation rec {
  pname = "nvidia-340-updated";
  version = "340.108";

  src = fetchFromGitHub {
    owner = "dkosmari";
    repo = "nvidia-340.108-updated";
    rev = "b09fbaea3dee9a63cc9e3046437998576da7d07e";
    sha256 = "b09fbaea3dee9a63cc9e3046437998576da7d07e"; # Замени после первой сборки
  };

  nativeBuildInputs = [ 
    autoPatchelfHook 
    makeWrapper 
    wget
    gnused
    gnugrep
    patchelf
  ];

  # Упрощаем buildInputs - убираем несуществующие переменные
  buildInputs = [ 
    stdenv.cc.libc
    stdenv.cc.cc
  ];

  dontConfigure = true;

  buildPhase = ''
    # Даем скриптам права на выполнение
    chmod +x apply-patch.sh
    chmod +x update.sh

    # Запускаем скрипт, который сам скачает и пропатчит .run файл
    echo "Запуск apply-patch.sh..."
    ./apply-patch.sh

    # Собираем модуль ядра через Makefile из репозитория
    echo "Сборка модуля ядра..."
    make KVERSION="${kernel.modDirVersion}" SYSSRC="${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
  '';

  installPhase = ''
    # Устанавливаем модуль ядра
    echo "Установка модуля ядра..."
    make KVERSION="${kernel.modDirVersion}" SYSSRC="${kernel.dev}/lib/modules/${kernel.modDirVersion}/build" INSTALL_MOD_PATH=$out install

    # Устанавливаем пользовательскую часть из пропатченного .run файла
    echo "Установка пользовательской части..."
    if [ -f "NVIDIA-Linux-x86_64-${version}.run" ]; then
      # Запускаем пропатченный .run файл только для пользовательской части
      ./NVIDIA-Linux-x86_64-${version}.run --no-kernel-module --accept-license --no-questions --no-backup
      
      # Копируем установленные файлы в $out
      mkdir -p $out/bin $out/lib $out/share/nvidia
      
      # Копируем бинарные файлы
      find /usr/bin -name "nvidia-*" -exec cp {} $out/bin/ \; 2>/dev/null || true
      
      # Копируем библиотеки  
      cp -r /usr/lib64/* $out/lib/ 2>/dev/null || true
      cp -r /usr/lib/* $out/lib/ 2>/dev/null || true
      
      # Копируем данные
      cp -r /usr/share/nvidia/* $out/share/nvidia/ 2>/dev/null || true
    else
      echo "Ошибка: Пропатченный .run файл не найден!"
      exit 1
    fi

    # Создаем обертки для бинарных файлов
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