{
  description = "NixOS desktop — Hyprland + Caelestia shell, NVIDIA 4070 Ti";

  inputs = {
    # Stable NixOS 26.05 (Yarara) — no more unstable rename churn
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # quickshell's self-hosted git (git.outfoxxed.me) is down/unreachable —
    # use the official GitHub mirror. No nixpkgs follows: quickshell/caelestia
    # are bleeding-edge and build against their own pinned nixpkgs.
    quickshell.url = "github:quickshell-mirror/quickshell";

    # Caelestia is NOT in nixpkgs — official flake only.
    caelestia-shell = {
      url = "github:caelestia-dots/shell";
      inputs.quickshell.follows = "quickshell";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs:
    let
      system = "x86_64-linux";
      username = "hravid"; # <<< CHANGE if your NixOS username is different
    in {
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs username; };
        modules = [
          ./configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit inputs username; };
            home-manager.users.${username} = import ./home.nix;
          }
        ];
      };
    };
}
