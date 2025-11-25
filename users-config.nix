{ config, lib, pkgs, ... }:

{
  users.users.mate = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "users" "vdoxusers" "adbusers" "scanner" "lp" ];
    hashedPassword = "$6$G1Iqe493JLGad8hm$BeldIA2FBoa810TvGR2qspBrQniaG3jDcRPOygQwoRRe6aE1nfHQ58kDdz9cM3LuovXQV99OiPzKdF/Qw/d0X0";
  };

  users.users.arseny = {
    isNormalUser = true;
    extraGroups = [ "users" "scanner" "lp" ];
    hashedPassword = "$y$j9T$WMVSGYYLehheD9kkHn1H9/$O1rsJ/D2esdXVQkI2QgrlMor7ZE/26Ve8BLGeEy8zy3";
  };

}