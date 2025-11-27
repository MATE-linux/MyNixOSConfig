{ config, lib, pkgs, ... }:

{
  programs.adb.enable = true;
  programs.firefox.enable = true;
  programs.java = {
    enable = true;
    package = pkgs.jdk;  # или pkgs.jdk11 для конкретной версии
  };
  programs.appimage = {
    enable = true;
    binfmt = true;
  };
  
  nixpkgs.config.android_sdk.accept_license = true;
  environment.systemPackages = with pkgs; [
    # vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    git
    wget
    xfce.xfce4-whiskermenu-plugin
    xfce.xfce4-pulseaudio-plugin
    xfce.xfce4-xkb-plugin
    neofetch
    telegram-desktop
    # Тема иконок Breeze (обязательно)
    kdePackages.breeze-icons
    kdePackages.breeze-gtk
    
    # Другие возможные зависимости
    gtk-engine-murrine    # Движок для тем GTK2
    gtk_engines          # Базовые движки GTK
    gsettings-desktop-schemas  # Для правильной работы настроек
    # Архиваторы
    file-roller      # Графический архиватор для GNOME/FCE
    kdePackages.ark              # Альтернативный архиватор для KDE
    p7zip            # Поддержка 7z архивов
  
    # Файловый менеджер с расширенными возможностями
    nautilus  # или pcmanfm для XFCE
  
    # Системные утилиты
    gnome-disk-utility  # Управление дисками
    gparted           # Редактор разделов
    baobab            # Анализатор дискового пространства

    # Обсидиан (заметки)
    obsidian
  
    # Редакторы кода
    vscode            # Visual Studio Code
  
    # Офисный пакет
    libreoffice-qt    # Версия с Qt интеграцией
  
    # Разработка под Android
    android-studio    # Полная среда разработки
  
    # Виртуализация
    virtualbox        # VirtualBox с host модулями 
    hunspell
    hunspellDicts.ru_RU
    hunspellDicts.en_US
    xed
    gimp
    vlc
    kdePackages.okular
    gnome-calculator
    # xfce4-clipman-plugin 
    thunderbird
    transmission-gtk
    simplescreenrecorder
    flameshot
    ksnip
    plasma5Packages.kdeconnect-kde
    stellarium
    kdePackages.dolphin
    file #показывает тип файла
    smartmontools #показывает инфу на диске
    hdparm
    #дрова для разных ФС
    exfat
    ntfs3g
    #androidenv.androidPkgs.androidsdk
    #androidenv.androidPkgs.platform-tools
    kotlin
    gedit
    cmatrix
    remmina
    nmap
    #(bottles.override { removeWarningPopup = true; })
    wineWowPackages.stable
    dxvk
    vkd3d
    winetricks
    dxvk
    vkd3d
    vkd3d-proton
    # Для NVIDIA
    #  nvidia-vaapi-driver
    # Дополнительные компоненты
    vulkan-tools
    vulkan-loader
    vulkan-validation-layers
    lutris
    playonlinux
    element-desktop
    vdrift
    nodejs
    seahorse
    gnome-keyring
    glxinfo
    # busybox
    pciutils
    sane-backends
    xsane
    usbutils
    kdePackages.skanlite
    awf
    gnome-tweaks 
    graphite-gtk-theme
    pnpm
    notepadqq
    gitnuro
    github-desktop
    waydroid
    weston
    luanti
    ticktick 
    gnome-keyring
    libsecret
    seahorse
    unstable.floorp-bin
    protonvpn-cli
    protonvpn-gui
    chromium
    openssl
    bitwarden
    gnome-clocks
    cinny-desktop
    xfce.libxfce4ui
    traceroute
    zeronsd
    zerotierone
    steam-run
    xsnow
  ];
}