{
  config, pkgs, lib, ...
}:
{
  options.system.build = lib.mkOption {
    internal = true;
    default = { };

    type = lib.types.submodule {
      freeformType = lib.types.lazyAttrsOf lib.types.anything;

      options = {
        nixos-rebuild = lib.mkOption {
          type = lib.types.package;
          default = pkgs.nixos-rebuild-ng;
          internal = true;
        };
      };
    };
  };

  config = {
    environment.systemPackages = [
      config.system.build.nixos-rebuild
    ];

    environment.etc."doas.conf".text = ''
      permit setenv { NIXOS_NO_CHECK=1 } test as root
      permit setenv { NIXOS_REBUILD_I_UNDERSTAND_THE_CONSEQUENCES_PLEASE_BREAK_MY_SYSTEM=1 } test as root
    '';
  };


  /*
  config = {
    environment.systemPackages = [
      opentmpfiles
      # nixos-enter and nixos-install depend on a systemd-tmpfiles implementation
      # see https://github.com/NixOS/nixpkgs/blob/80bdc1e5ce51f56b19791b52b2901187931f5353/pkgs/by-name/ni/nixos-enter/nixos-enter.sh#L108 for details
      (lib.lowPrio (
        pkgs.writeShellScriptBin "systemd-tmpfiles" ''
          exec "${pkgs.opentmpfiles}/bin/tmpfiles.opentmpfiles" "$@"
        ''
      ))
    ];
  };

  */
}
