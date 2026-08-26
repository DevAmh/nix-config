# vm.nix
{ config, lib, pkgs, ... }:

{
  options.system.build.vm = lib.mkOption {
    type = lib.types.package;
    description = "A script to run the VM.";
  };

  config.system.build.vm =
    let
      diskImage = import "${pkgs.path}/nixos/lib/make-disk-image.nix" {
        inherit lib config pkgs;
        format = "qcow2";
        partitionTableType = "legacy"; # or "efi" if you boot UEFI
        # This must match whatever your fileSystems."/" is currently
        # keyed on so your initrd finds it the same way it would on
        # real hardware.
        label = "slam-x86_64";
      };
    in
    pkgs.writeShellScriptBin "run-vm" ''
      exec ${pkgs.qemu_kvm}/bin/qemu-system-x86_64 \
        -name test-vm \
        -m ${toString config.virtualisation.memorySize} \
        -smp ${toString config.virtualisation.cores} \
        -kernel ${config.boot.kernelPackages.kernel}/bzImage \
        -initrd ${config.boot.initrd.package}/initrd \
        -drive file=${diskImage}/nixos.qcow2,if=virtio \
        -nographic \
        -enable-kvm \
        "$@"
    '';
}
