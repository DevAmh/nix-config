{ config, lib, pkgs, ... }:
let
  cfg = config.virtualisation;
  kernelParams = lib.concatStringsSep " " (
    config.boot.kernelParams ++ [
      "init=${config.system.build.toplevel}/scripts/init"  # Correct path for SLAM
      "console=ttyS0"
    ]
  );
in {
  options.system.build.vm = lib.mkOption {
    type = lib.types.package;
    description = "A script to run the VM.";
  };


  config.system.build.vm = pkgs.writeShellScriptBin "run-vm" ''
    set -e
    workdir=$(mktemp -d)
    cp ${config.system.image.builds.extRoot.out} "$workdir/root.img"
    chmod +w "$workdir"/*.img

    exec ${pkgs.qemu_kvm}/bin/qemu-system-x86_64 \
      -name test-vm \
      -m ${toString cfg.memorySize} \
      -smp ${toString cfg.cores} \
      -kernel ${config.boot.kernelPackages.kernel}/bzImage \
      -initrd ${config.boot.initrd.package}/initrd \
      -append "${kernelParams}" \
      -drive file="$workdir/root.img",if=virtio,format=raw \
      -nographic \
      -enable-kvm \
      "$@"
  '';
}
