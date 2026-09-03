{pkgs, config, lib, slamSrc, inputs, ...}:
{
  fileSystems."/" = {
    device = "/dev/disk/by-label/slam-x86_64";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/EFIBOOT";
    options = [
      "fmask=0022"
      "dmask=0022"
    ];
  };

  # Include support for various filesystems and tools to create / manipulate them.
  boot.supportedFilesystems =
    [
      "f2fs"
      "vfat"
      "xfs"
      "zfs"
    ]
    |> map (name: {
      inherit name;
      value.enable = true;
    })
    |> builtins.listToAttrs;

  # Configure host id for ZFS to work
  networking.hostId = lib.mkDefault "8425e349";

  programs.fish = {
    enable = true;
    package = pkgs.fishMinimal;
  };

   environment.etc."fish/config.fish".text = ''
     set -gx NIXOS_REBUILD_I_UNDERSTAND_THE_CONSEQUENCES_PLEASE_BREAK_MY_SYSTEM 1
   '';


  doas = {
    enable = true;
    rules = [
      {
        identity = "test";
        options = [
          "nopass"
        ];
      }
    ];
  };

  # Make <slam> and <nixpkgs> available for import.
  security.pam.environment = {
    NIX_PATH.default = "slam=${slamSrc}:nixpkgs=${slamSrc}/nixpkgs";
  };

  services.dhcpcd.enable = true;

  services.nix-daemon = {
    enable = true;
    settings = {
      trusted-public-keys = [
        "narcache.informatics.coop:S7aqboQhIrofJ6Oxc2mqy8rLnrnHOz8nBapwScBzbsE="
        "cache.tvl.su:kjc6KOMupXc1vHVufJUoDUYeLzbwSr9abcAKdn/U1Jk="
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      ];
      substituters = [
        "https://narcache.informatics.coop"
        "https://cache.tvl.su"
        "https://cache.nixos.org/"
      ];
    };
  };

  services.dmesg.enable = true;

  services.getty = {
    enable = true;
    ttys = [
      "ttyS0" "tty1" "tty2" "tty3" "tty4" "tty5" "tty6"
    ];
  };

  services.seatd.enable = true;
  services.greetd = {
    enable = false;
    settings = {
      vt = 6;
      initial_session = {
        user = "test";
        command = "/run/current-system/sw/bin/fish -l";
      };
    };
  };

  services.wpa_supplicant = {
    enable = true;
    allowAuxiliaryImperativeNetworks = true;
    userControlled.enable = true;
  };

  system.synit = {
    plan.config.testListener = [
      ''
        # TODO: generate a sturdyref and display it on the console.
        $machine ? <ip address _ _ { "local": ?addr }> [
          $config += <require-service  <relay-listener <tcp $addr 24> $config>>
        ]
      ''
    ];
  };

  system.activation.scripts = {
    chpasswd = {
      deps = [ "users" ];
      text = ''
        for o in $(</proc/cmdline); do
          case "$o" in
            passwd=*)
              set -- $(IFS==; echo $o)
              echo "test:$2" | ${pkgs.shadow}/bin/chpasswd
              ;;
          esac
        done
      '';
    };
    init-profile = {
      lang = "execline";
      text = ''
        if -t { eltest ! -L /nix/var/nix/profiles/system }
        if { mkdir -p /nix/var/nix/profiles }
        importas -S systemConfig
        ${config.services.nix-daemon.package}/bin/nix-env --profile /nix/var/nix/profiles/system --set $systemConfig
      '';
    };
  };

  system.s6 = {
    logToConsole = true;
    verbosity = 2;
  };

  # Use less privileged test user
  users.users.test = {
    #uid = 1000;
    isNormalUser = true;
    group = "users";
    createHome = true;
    home = "/home/test";
    extraGroups = [
      "wheel"
      "video"
    ];
    shell = config.programs.fish.package;
    # Allow the graphical user to login without password
    initialHashedPassword = "";

    synit = {
      systemBus = "$config";
    };
  };

  # Allow the user to log in as root without a password.
  users.users.root.initialHashedPassword = "";

  # allow nix-copy to live system
  nix.settings.trusted-users = [ "test" ];

  # We run sshd by default. Login is only possible after adding a
  # password via "passwd" or by adding a ssh key to ~/.ssh/authorized_keys.
  # The latter one is particular useful if keys are manually added to
  # installation device for head-less systems i.e. arm boards by manually
  # mounting the storage in a different system.
  services.openssh = {
    enable = lib.mkDefault true;
    settings.PermitRootLogin = lib.mkDefault "yes";
  };

  environment.systemPackages = with pkgs; [
    git
  ];



  # Tell the Nix evaluator to garbage collect more aggressively.
  # This is desirable in memory-constrained environments that don't
  # (yet) have swap set up.
  # environment.variables.GC_INITIAL_HEAP_SIZE = "1M";

  # Make the installer more likely to succeed in low memory
  # environments.  The kernel's overcommit heustistics bite us
  # fairly often, preventing processes such as nix-worker or
  # download-using-manifests.pl from forking even if there is
  # plenty of free memory.
  boot.kernel.sysctl."vm.overcommit_memory" = "1";
  boot.kernelParams = [ "console=tty0" "console=ttyS0,115200" "loglevel=7" ];

  hardware.console.keyMap = "us";

  nix.settings.experimental-features = [
    "nix-command" "flakes" "pipe-operators"
  ];

  # Make firmware available.
  hardware.firmware = [ pkgs.linux-firmware ];

  system.synit.enable = true;
  system.serviceManager = "s6";
  boot.serviceManager = "s6";
}
