# SPDX-FileCopyrightText: 2026 Emery Hemingway
#
# SPDX-License-Identifier: PPL

{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    toUuid
    types
    ;

  archName = pkgs.stdenv.hostPlatform.uname.processor;

  rootType =
    {
      "aarch64" = "B921B045-1DF0-41C3-AF44-4C6F280D3FAE";
      "i686" = "44479540-F297-41B2-9AF7-D131D5F0458A";
      "loongarch64" = "77055800-792C-4F94-B39A-98C91B762BB6";
      "x86_64" = "4F68BCE3-E8CD-4DB1-96E7-FBCAF984B709";
    }
    .${archName} or "0FC63DAF-8483-4772-8E79-3D69D8477DE4";

  cfg = config.system.image;
in
{
  options = {
    system.image.extRoot = {
      enable = mkEnableOption "root file-system on an ext file-system";
      type = mkOption {
        description = "Ext filesystem type.";
        default = "ext4";
        type = types.str;
      };
      label = mkOption {
        description = "Ext file-system label";
        default = "slam-${archName}";
        type = types.str;
      };
      expandAtBoot = mkEnableOption "expanding the file-system before booting" // {
        default = true;
      };
    };
  };

  config = mkIf cfg.extRoot.enable {

    fileSystems."/" = lib.mkImageMediaOverride {
      fsType = cfg.extRoot.type;
      device = "/dev/disk/by-label/${cfg.extRoot.label}";
    };

    boot.initrd.mountScripts = mkIf cfg.extRoot.expandAtBoot {
      "mount/".deps = [ "expand/" ];
      "expand/" = {
        deps = [
          "device/"
          "fsck/"
        ];
        text =
          let
            inherit (config.fileSystems."/") device;
          in
          ''
            foreground {
              if { grep -q slam_resize_root /proc/cmdline }
              backtick -E PKNAME {
                lsblk -n -o PKNAME ${device}
              }
              backtick -E PARTN {
                lsblk -n -o PARTN ${device}
              }
              if {
                heredoc 0 ,+, sfdisk -N $PARTN --no-reread /dev/$PKNAME
              }
              if {
                fsck.ext2 -f -y ${device}
              }
              resize2fs ${device}
            }
          '';
      };
    };

    system.image.builds.extRoot = pkgs.callPackage ./utils/make-ext2fs.nix {
      storeContents = config.system.image.store.contents;
      inherit (cfg.extRoot) label type;
    };

    system.image.builds.diskImage =
      pkgs.runCommand "disk.img"
        {
          __structuredAttrs = true;
          unsafeDiscardReferences.out = true;
          buildInputs = [
            pkgs.limine
          ];
          nativeBuildInputs = [
            pkgs.util-linux
          ]
          ++ cfg.builds.esp.nativeBuildInputs
          ++ cfg.builds.extRoot.nativeBuildInputs;
        }
        # Stack buildCommand from other
        # derivations to avoid building them as
        # intermediate steps.
        ''
          img=$out

          truncate --size=1M $img
          truncate --size=+32K $img

          espByteOffset=$(stat --printf='%s' $img)
          (
          out=$(realpath ./esp.img)
          ${cfg.builds.esp.buildCommand}
          )
          cat ./esp.img >> $out

          # Root file-system.
          truncate --size=%1M $img
          extByteOffset=$(stat --printf='%s' $img)
          (
          ${cfg.builds.extRoot.buildCommand}
          )

          # Align and pad to 1MiB.
          truncate --size=%1M $img
          truncate --size=+1M $img

          # Create partition table.
          tableGuid=${"out" |> placeholder |> toUuid}
          espGuid=${
            "out"
            |> placeholder
            |> (out: "${out} esp")
            |> toUuid
          }
          extGuid=${
            "out"
            |> placeholder
            |> (out: "${out} slam")
            |> toUuid
          }
          rootType=${rootType}
          sectorSize=512
          sfdisk $img <<EOF
            grain: 32768
            label: gpt
            label-id: $tableGuid
            ''${out}2 : start=$(( $extByteOffset / $sectorSize )), uuid=$extGuid, type=$rootType,
            ''${out}1 : start=$(( $espByteOffset / $sectorSize )), uuid=$espGuid, type=U
            ''${out}128 : start=1M, size=32K, uuid=$espGuid, type=21686148-6449-6E6F-744E-656564454649
          EOF

          limine bios-install $out 128
        '';

    system.image.builds.diskImageQcow2 =
      pkgs.runCommand "${cfg.builds.diskImage.name}.qcow2"
        {
          __structuredAttrs = true;
          unsafeDiscardReferences.out = true;

          nativeBuildInputs = [
            pkgs.qemu-utils
          ]
          ++ cfg.builds.diskImage.nativeBuildInputs;
          inherit (cfg.builds.diskImage) buildInputs;
        }

        ''
          (
            out=$(realpath ./tmp.img)
            ${cfg.builds.diskImage.buildCommand}
          )

          qemu-img convert -f raw -O qcow2 \
            -c -o compression_type=zstd \
            ./tmp.img $out

          qemu-img resize $out 16G
        '';

    system.image.builds.diskImageZstd =
      pkgs.runCommand "${cfg.builds.diskImage.name}.zstd"
        {
          __structuredAttrs = true;
          unsafeDiscardReferences.out = true;

          nativeBuildInputs = [
            pkgs.zstd
          ]
          ++ cfg.builds.diskImage.nativeBuildInputs;
          inherit (cfg.builds.diskImage) buildInputs;
        }
        ''
          (
            out=$(realpath ./tmp.img)
            ${cfg.builds.diskImage.buildCommand}
          )
          zstd <./tmp.img >$out
        '';
  };
}
