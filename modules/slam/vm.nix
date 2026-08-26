{config, lib, pkgs, ...}:
let
  cfg = config.virtualization;
in
{
  virtualisation = {
    memorySize = 2048;
    cores = 2;
  };
}
