{inputs, ...}:
{
  lib ? null,
  specialArgs ? { },
  modules ? [ ],
 # overlays ? [ ],
 #altOverlays ? [ ],
  ...
}:
let
  system = "x86_64-linux";

  slam = import inputs.slam {
    #inherit overlays altOverlays
    inherit system;
  };
in
slam.evalSlam {
  modules = modules ++ [
    ./system/rebuild.nix
    ./config.nix #./vm.nix ./mutable.nix
  ];
}
