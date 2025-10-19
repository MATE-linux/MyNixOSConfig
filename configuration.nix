# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:
let
  nvidia340Updated = pkgs.callPackage ./nvidia-340-updated.nix {
    kernel = config.boot.kernelPackages.kernel;
  };
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = true;
  # boot.loader.grub.efiSupport = true;
  # boot.loader.grub.efiInstallAsRemovable = true;
  # boot.loader.efi.efiSysMountPoint = "/boot/efi";
  # Define on which hard drive you want to install Grub.
  boot.loader.grub.device = "/dev/sda"; # or "nodev" for efi only

  boot.kernel.sysctl = {
    # Устанавливаем vm.swappiness в 10
    # Это заставляет систему использовать swap только при крайней необходимости
    "vm.swappiness" = 10;
  };
    # Параметры ядра для гибернации
  boot = {
    resumeDevice = "/dev/disk/by-uuid/f5e5169b-4d21-4b65-b7a8-5c314177a50f";
    kernelParams = [
      "resume=UUID=f5e5169b-4d21-4b65-b7a8-5c314177a50f" # И снова тот же UUID
    ];
    
    # Для некоторых систем может потребоваться дополнительная настройка
    #extraModprobeConfig = ''
    #  options nvidia NVreg_EnableSuspend=1
    #  options nvidia NVreg_EnableMSI=1
    #'';
  };





  # Используем наш кастомный драйвер
  #boot.extraModulePackages = [ nvidia340Updated ];
  
  # Отключаем nouveau
  #boot.blacklistedKernelModules = [ "nouveau" ];
  #boot.kernelModules = [ "nvidia" ];

  # Включаем драйверы NVIDIA
  #services.xserver.videoDrivers = [ "nvidia" ];
  
  # Настройки NVIDIA
  #hardware.nvidia.modesetting.enable = true;

  #hardware.nvidia.open = false;






  # Настройки systemd для гибернации
  systemd = {
    sleep.extraConfig = ''
      HibernateMode=shutdown
      HybridSleepMode=shutdown
    '';
  };

  # Настройки управления питанием
  powerManagement = {
    enable = true;
    resumeCommands = ''
      echo "Восстановление из гибернации..."
    '';
  };
  networking.hostName = "nixos-MSI"; # Define your hostname.
  # Pick only one of the below networking options.
  #networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.
  networking.firewall = {
    allowedTCPPortRanges = [ { from = 1714; to = 1764; } ];
    allowedUDPPortRanges = [ { from = 1714; to = 1764; } ];
  };
  # Set your time zone.
  time.timeZone = "Europe/Saratov";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  i18n.defaultLocale = "ru_RU.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };
  hardware.sane.enable = true;
  hardware.graphics.enable = true;
  # Enable the X11 windowing system.
  services.xserver.enable = true;
  # Enable the GNOME Desktop Environment.
  # services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.xfce.enable = true;  

  # Configure keymap in X11
  services.xserver.xkb.layout = "us,ru";
  services.xserver.xkb.options = "grp:alt_shift_toggle";
  # Enable CUPS to print documents.
  # services.printing.enable = true;
  # В раздел конфигурации services.printing
  services.printing = {
    enable = true;
    # Драйвер можно найти через поиск в nixpkgs, например: nix-env -qaP '*gutenprint*'
    drivers = [ pkgs.gutenprint ]; # Gutenprint поддерживает многие старые модели Canon:cite[2]
  };
  # Права доступа к USB-сканеру
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTRS{idVendor}=="04a9", ATTRS{idProduct}=="????", MODE="0666", GROUP="lp", ENV{libsane_matched}=="yes", RUN+="${pkgs.acl}/bin/setfacl -m g:scanner:rw $env{DEVNAME}"
  '';
  # Enable sound.
  # services.pulseaudio.enable = true;
  # OR
  # services.pipewire = {

  #   enable = true;
  #   pulse.enable = true;
  # };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.libinput.enable = true;

  # Разрешить несвободные пакеты (необходимо для VirtualBox, Android Studio)
  nixpkgs.config.allowUnfree = true;

  # Настройки VirtualBox
  virtualisation.virtualbox.host = {
    enable = true;
    enableExtensionPack = true;  # Расширения для USB и др.
  };
  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.mate = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "users" "vdoxusers" "adbusers" "scanner" "lp"  ]; # Enable ‘sudo’ for the user.
    hashedPassword = "$6$G1Iqe493JLGad8hm$BeldIA2FBoa810TvGR2qspBrQniaG3jDcRPOygQwoRRe6aE1nfHQ58kDdz9cM3LuovXQV99OiPzKdF/Qw/d0X0";
    packages = with pkgs; [
      tree
    ];
  };
  programs.adb.enable = true;
  programs.firefox.enable = true;
  programs.java = {
    enable = true;
    package = pkgs.jdk;  # или pkgs.jdk11 для конкретной версии
  };
  nixpkgs.config.android_sdk.accept_license = true;
  services.flatpak.enable = true;
  xdg.portal = {
    enable = true;
    # Укажите необходимые порталы в зависимости от вашего окружения
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk # Базовый портал для GTK-приложений
      # xdg-desktop-portal-kde # Раскомментируйте, если используете KDE Plasma
      # xdg-desktop-portal-wlr # Раскомментируйте, если используете Sway или Hyprland
    ];
  };
  environment.pathsToLink = [ "/share/xdg-desktop-portal" "/share/applications" ];
  programs.appimage.enable = true;
  programs.appimage.binfmt = true;
  #  android_sdk.accept_license = true;
  #  programs.kdeconect.enable = true;
  # List packages installed in system profile 
  # You can use https://search.nixos.org/ to find more packages (and options).
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
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
    minetest
    luanti 
    (callPackage ./nvidia-340-updated.nix { 
      kernel = config.boot.kernelPackages.kernel; 
    })
  ];
  #qt = {
  #  enable = true;
  #  platformTheme = "kde";  # или "kde"
  #  style = "breeze";
  #};
  
  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };
  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "25.05"; # Did you read the comment?

}

