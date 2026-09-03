{inputs, nixpkgs, slam, ...}:
{
  modules ? [],
  specialArgs ? {},
  ...
}:
let
  system = "x86-64_linux";
  pkgs = nixpkgs.legacyPackages.${system};
  pkgsSlam = pkgs.extend (final: prev:
    import (slam + "/overlays/slam.nix") final prev
  );

  slamRoot = import slam {};
in
slamSystem = slamRoot.evalSlam {
  modules = modules;
  specialArgs = specialArgs;
};
