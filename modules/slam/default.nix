{inputs, ...}:
{
  modules ? [],
  specialArgs ? {},
  overlays ? [ ],
  altOverlays ? { },
  ...
}:
let
  slam = import inputs.slam {
    inherit overlays altOverlays;
  };

  inherit (slam) pkgs lib;
in
slam.evalSlam {
  modules = modules;
  specialArgs = specialArgs;
}
