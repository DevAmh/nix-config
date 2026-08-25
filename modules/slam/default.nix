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
    system = "x86_64-linux";
  };

  inherit (slam) pkgs lib;
in
slam.evalSlam {
  modules = modules;
  specialArgs = specialArgs;
}
