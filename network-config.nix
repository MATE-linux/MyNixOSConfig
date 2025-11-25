{ config, lib, pkgs, ... }:

{
  networking.hostName = "nixos-MSI";
  networking.networkmanager.enable = true;
  
  networking.firewall = {
    allowedTCPPorts = [ 8222 ];
    allowedUDPPorts = [ 30000 ];
    allowedTCPPortRanges = [ { from = 1714; to = 1764; } ];
    allowedUDPPortRanges = [ { from = 1714; to = 1764; } ];
  };
}