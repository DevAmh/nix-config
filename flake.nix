{
  inputs = {
    # nixpkgs repository containing packages and functions.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # slam System Layer Abstraction Modules
    slam.url = "git+https://git.informatics.coop/nix/slam";

    slam-images.url = "git+https://git.informatics.coop/nix/slam-images";
    slam-images.flake = false;
  };

  outputs = inputs: let
    system = "x86_64-linux";
  in rec {
     lib.slamSystem = import ./modules/slam {
       inherit inputs;
     };

     nixosConfigurations.slam = lib.slamSystem {
       modules = [
         ./configuration.nix
         ./modules/slam/activation/rebuild.nix
       ];
       specialArgs = {inherit inputs;};
     };
   };
}
