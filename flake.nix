{
  description = "Ничего здесь не трогать!!!";

  inputs = {
    # Используйте стабильную ветку nixpkgs, например, nixos-25.05
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    
    # При желании, home-manager также можно зафиксировать на стабильной версии
    # home-manager.url = "github:nix-community/home-manager/release-25.05";

    # Добавляем нестабильный канал для Floorp
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }@inputs: {
    nixosConfigurations.nixos-MSI = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
        # home-manager.nixosModules.home-manager
        # {
        #   home-manager.useGlobalPkgs = true;
        #   home-manager.useUserPackages = true;
        #   home-manager.users.ваше-имя-пользователя = import ./home.nix;
        # }
        {
          # Добавляем overlay для нестабильных пакетов
          nixpkgs.overlays = [
            (final: prev: {
              unstable = import nixpkgs-unstable {
                system = "x86_64-linux";
                config.allowUnfree = true;
              };
            })
          ];
        }
      ];
    };
  };
}