{ config, lib, pkgs, ... }:

{
  hardware.graphics.enable = true;
  
  services.xserver = {
    enable = true;
    desktopManager.xfce.enable = true;
    xkb = {
      layout = "us,ru";
      options = "grp:alt_shift_toggle";
    };
  };

  services.gnome.gnome-keyring.enable = true;
  programs.seahorse.enable = true;
  
  security.pam = {
    services.login.enableGnomeKeyring = true;
    services.gdm.enableGnomeKeyring = true;
  };

  environment.sessionVariables = {
    SSH_AUTH_SOCK = "/run/user/1000/keyring/ssh";
  };

  programs.git = {
    enable = true;
    config = {
      credential.helper = "store";
    };
  };

  environment.variables = {
    ELECTRON_ENABLE_SECURITY_WARNINGS = "1";
  };
}