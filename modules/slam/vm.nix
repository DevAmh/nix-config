# vm.nix
{ config, lib, pkgs, ... }:

let
  cfg = config.virtualisation;
  kernelParams = lib.concatStringsSep " " (
    config.boot.kernelParams ++ [ "init=${config.system.build.toplevel}/init" ]
  );
in {
  options.virtualisation = {
    memorySize = lib.mkOption { type = lib.types.int; default = 1024; };
    cores      = lib.mkOption { type = lib.types.int; default = 2; };
  };

  options.system.build.vm = lib.mkOption {
    type = lib.types.package;
    description = "A script to run the VM.";
  };

  config.system.build.vm = pkgs.writeShellScriptBin "run-vm" ''
    exec ${pkgs.qemu_kvm}/bin/qemu-system-x86_64 \
      -name test-vm \
      -m ${toString cfg.memorySize} \
      -smp ${toString cfg.cores} \
      -kernel ${config.system.build.kernel}/bzImage \
      -initrd ${config.system.build.initialRamdisk}/initrd \
      -append "${kernelParams} console=ttyS0" \
      -virtfs local,path=/nix/store,mount_tag=nix-store,security_model=none \
      -nographic \
      -enable-kvm \
      "$@"
  '';
}
