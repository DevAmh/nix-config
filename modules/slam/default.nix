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

  nixpkgsConfigShim = { lib, ... }: {
    options.nixpkgs.config = lib.mkOption {
      type = lib.types.attrs;
      default = { };
    };
  };
in
slam.evalSlam {
  modules = modules ++ [nixpkgsConfigShim];
  specialArgs = specialArgs;
}
