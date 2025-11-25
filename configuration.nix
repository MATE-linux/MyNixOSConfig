{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./boot-config.nix
    ./network-config.nix
    ./locale-config.nix
    ./desktop-config.nix
    ./printing-config.nix
    ./services-config.nix
    ./users-config.nix
    ./packages-config.nix
    ./virtualisation-config.nix
    ./nix-settings.nix
  ];

  nixpkgs.config.allowUnfree = true;
  system.stateVersion = "25.05";
}