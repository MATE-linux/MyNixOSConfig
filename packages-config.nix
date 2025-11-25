{ config, lib, pkgs, ... }:

{
  programs.adb.enable = true;
  programs.firefox.enable = true;
  programs.java.enable = true;
  programs.appimage = {
    enable = true;
    binfmt = true;
  };
  
  nixpkgs.config.android_sdk.accept_license = true;
  environment.systemPackages = with pkgs; [
    git wget neofetch telegram-desktop
    kdePackages.breeze-icons kdePackages.breeze-gtk
    gtk-engine-murrine gtk_engines gsettings-desktop-schemas
    
    # Архиваторы и файловые менеджеры
    file-roller kdePackages.ark p7zip nautilus
    gnome-disk-utility gparted baobab
    
    # Приложения
    obsidian vscode libreoffice-qt android-studio
    virtualbox hunspell hunspellDicts.ru_RU hunspellDicts.en_US
    xed gimp vlc kdePackages.okular gnome-calculator
    thunderbird transmission-gtk simplescreenrecorder
    flameshot ksnip plasma5Packages.kdeconnect-kde
    stellarium kdePackages.dolphin file
    smartmontools hdparm exfat ntfs3g
    kotlin gedit cmatrix remmina nmap
    
    # Wine и игровые пакеты
    wineWowPackages.stable dxvk vkd3d winetricks
    vkd3d-proton vulkan-tools vulkan-loader
    vulkan-validation-layers lutris playonlinux
    
    # Другие пакеты
    element-desktop vdrift nodejs seahorse
    gnome-keyring glxinfo pciutils sane-backends
    xsane usbutils kdePackages.skanlite awf
    gnome-tweaks graphite-gtk-theme pnpm notepadqq
    gitnuro github-desktop waydroid weston luanti
    ticktick libsecret unstable.floorp-bin
    protonvpn-cli protonvpn-gui chromium openssl
    bitwarden gnome-clocks cinny-desktop xfce.libxfce4ui
    traceroute zeronsd zerotierone steam-run
  ];
}