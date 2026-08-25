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
    system = pkgs.stdenv.hostPlatform.system;
  };

  inherit (slam) pkgs lib;
in
slam.evalSlam {
  modules = modules;
  specialArgs = specialArgs;
}
