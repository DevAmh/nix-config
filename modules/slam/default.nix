{inputs, ...}:
{
  modules ? [],
  specialArgs ? {},
  overlays ? [ ],
  altOverlays ? { },
  ...
}:
let
  slam = "${inputs.slam}/default.nix" {
    inherit overlays altOverlays;
  };

  inherit (slam) pkgs lib;
in
slam.evalSlam {
  modules = modules;
  specialArgs = specialArgs;
}
