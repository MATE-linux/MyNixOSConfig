{ config, lib, pkgs, ... }:

{
  boot.loader.grub = {
    enable = true;
    device = "/dev/sda";
  };

  boot.kernel.sysctl = {
    "vm.swappiness" = 10;
  };

  boot = {
    resumeDevice = "/dev/disk/by-uuid/f5e5169b-4d21-4b65-b7a8-5c314177a50f";
    kernelParams = [
      "resume=UUID=f5e5169b-4d21-4b65-b7a8-5c314177a50f"
    ];
  };

  systemd = {
    sleep.extraConfig = ''
      HibernateMode=shutdown
      HybridSleepMode=shutdown
    '';
  };

  powerManagement = {
    enable = true;
    resumeCommands = ''
      echo "Восстановление из гибернации..."
    '';
  };
}