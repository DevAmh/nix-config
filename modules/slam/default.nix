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
  slam = import inputs.slam {
    inherit overlays altOverlays;
    system = "x86_64-linux";
  };
in
slam.evalSlam {
  modules = modules;
}
