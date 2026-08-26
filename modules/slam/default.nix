{inputs, ...}:
{
  lib ? null,
  specialArgs ? { },
  modules ? [ ],
  overlays ? [ ],
  altOverlays ? [ ],
  ...
}:
let
  system = "x86_64-linux";

  slam = import inputs.slam {
    inherit overlays altOverlays system;
  };
in
slam.evalSlam {
  modules = modules;
}
