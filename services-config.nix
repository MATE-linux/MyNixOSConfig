{ config, lib, pkgs, ... }:

let
  vaultwardenSecrets = pkgs.writeShellScript "vaultwarden-setup" ''
    if [ ! -f /etc/vaultwarden.env ]; then
      ADMIN_TOKEN=$(openssl rand -base64 48)
      cat > /etc/vaultwarden.env << EOF
    ADMIN_TOKEN=$ADMIN_TOKEN
    EOF
      chmod 600 /etc/vaultwarden.env
      echo "Секретный файл создан: /etc/vaultwarden.env"
    fi
  '';
in
{
  services.vaultwarden = {
    enable = true;
    config = {
      DOMAIN = "http://localhost";
      ROCKET_ADDRESS = "0.0.0.0";
      ROCKET_PORT = 8222;
      SIGNUPS_ALLOWED = true;
      INVITATIONS_ALLOWED = true;
      SIGNUPS_VERIFY = false;
      USE_SYSLOG = false;
      LOG_LEVEL = "warn";
      EXTENDED_LOGGING = true;
    };
    dbBackend = "sqlite";
    environmentFile = "/etc/vaultwarden.env";
  };

  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global = {
        workgroup = "MYGROUP";
        security = "user";
        "map to guest" = "bad user";
        "guest account" = "nobody";
        "usershare allow guests" = "yes";
      };
    };
    shares = {
      public = {
        path = "/mnt/files";
        "read only" = "no";
        "guest ok" = "yes";
        "browseable" = "yes";
        "public" = "yes";
        "writeable" = "yes";
        "create mask" = "0666";
        "directory mask" = "0777";
        "force user" = "nobody";
        "force group" = "nogroup";
      };
    };
  };

  services.flatpak.enable = true;
  
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];
  };
  
  environment.pathsToLink = [ "/share/xdg-desktop-portal" "/share/applications" ];
}