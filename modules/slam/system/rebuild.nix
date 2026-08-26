{ config, pkgs, lib, ... }:
{
  options.system.build.nixos-rebuild = lib.mkOption {
    type = lib.types.package;
    default = pkgs.nixos-rebuild-ng;
    internal = true;
  };
}
