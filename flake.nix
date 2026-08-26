{
  inputs = {
    # nixpkgs repository containing packages and functions.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # slam System Layer Abstraction Modules
    slam.url = "git+https://git.informatics.coop/nix/slam";

    slam-images.url = "git+https://git.informatics.coop/nix/slam-images";
    slam-images.flake = false;
  };

  outputs = inputs: {
    lib.slamSystem =
      (import "${inputs.slam-images}/default.nix" {
        slamSrc = inputs.slam;
      }).evalSystem;
  };
}
