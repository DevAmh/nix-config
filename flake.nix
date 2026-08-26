{
  inputs = {
    # nixpkgs repository containing packages and functions.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # slam System Layer Abstraction Modules
    slam.url = "git+https://git.informatics.coop/nix/slam";
    slam-images.url = "git+https://git.informatics.coop/nix/slam-images";
  };

  outputs = inputs: {
    #lib.slamSystem = import ./modules/slam {inherit inputs;};
    lib.slamSystem = import "${inputs.slam-images}";
  };
}
