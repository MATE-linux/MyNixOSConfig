{ config, lib, pkgs, ... }:

{
  hardware.sane.enable = true;

  services.printing = {
    enable = true;
    drivers = [ pkgs.gutenprint ];
  };

  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTRS{idVendor}=="04a9", ATTRS{idProduct}=="????", MODE="0666", GROUP="lp", ENV{libsane_matched}=="yes", RUN+="${pkgs.acl}/bin/setfacl -m g:scanner:rw $env{DEVNAME}"
  '';
}