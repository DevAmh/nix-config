{
  lib,
  config,
  pkgs,
  slamSrc,
  ...
}:
{
  imports = map (p: slamSrc + /modules + p) [
    /programs/fish
    /services/getty
    /services/greetd
    /services/seatd
    /services/openssh
    /services/wpa_supplicant
  ];

  boot.serviceManager = "s6";
  boot.initrd.availableKernelModules = [
    "ahci"
    "nvme"
    "sata_inic162x"
    "sata_nv"
    "sata_promise"
    "sata_qstor"
    "sata_sil"
    "sata_sil24"
    "sata_sis"
    "sata_svw"
    "sata_sx4"
    "sata_uli"
    "sata_via"
    "sata_vsc"
    "sdhci_pci"
    "sd_mod"
    "uas"
    "usb_storage"
    "virtio_balloon"
    "virtio_blk"
    "virtio_blk"
    "virtio_console"
    "virtio_console"
    "virtio_mmio"
    "virtio_net"
    "virtio_net"
    "virtio_pci"
    "virtio_pci"
    "virtio_scsi"
  ];

  environment.etc."fish/config.fish".text = ''
    set -l normal (set_color --reset)
    set -l highlight (set_color -o green)
    set -g fish_greeting '
     Welcome to the experimental SLAM livecd.

     Some useful commands:
      -$highlight doas$normal run commands as root
      -$highlight s6 live$normal interact with s6 services
      -$highlight s6-logwatch$normal to read logs in /var/log.
      -$highlight irc-join$normal join the Syndicate IRC channel.
      -$highlight help$normal instructions on how to use fish.
    '

    set -a fish_complete_path /run/current-system/sw/share/fish/vendor_completions.d/

    # Preload some hints into the history.
    history append \
        'git clone https://git.syndicate-lang.org/synit/synit-template.git' \
        'nix-env -i -A pkgs.hello' \
        'npins add forgejo git.informatics.coop nix slam -b trunk' \
        'senpai -nickname slam-guest' \
        's6-logwatch /var/log/dmesg | s6-tai64ndiff' \
        's6-logwatch /var/log/syslog | s6-tai64ndiff' \
        's6-logwatch /var/log/system-bus | s6-tai64ndiff' \
        's6 live status' \
        's6 live restart dhcpcd' \
        'service -h' \
        'service daemon' \
        'service relay-listener' \
        'wpa_cli add_network' \
        'wpa_cli scan' \
        'wpa_cli 0 ssid ""' \
        'wpa_cli 0 psk ""' \
        ;

    function irc-join
        if test ! -e ~/.config/senpai/senpai.scfg
            mkdir -p ~/.config/senpai
            echo 'address "irc.libera.chat:6697"' >>~/.config/senpai/senpai.scfg
            echo 'nickname "synit-guest"' >>~/.config/senpai/senpai.scfg
            echo 'channel "#syndicate" "#synit"' >>~/.config/senpai/senpai.scfg
        end
        senpai
    end

    function sudo -w doas
      command doas $argv
    end

    fish_add_path ~/.nix-profile/bin
  '';

  environment.systemPackages = builtins.attrValues {
    inherit (pkgs)
      ddrescue
      efibootmgr
      efivar
      gitMinimal
      gptfdisk
      lynx
      nano
      npins
      inetutils
      pciutils
      screen
      senpai
      testdisk
      tmux
      vim
      ;
  };

  fileSystems."/" = {
    #device = "/dev/disk/by-label/slam-x86_64";
    device = "/dev/vda";
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

  doas = {
    enable = true;
    rules = [
      {
        identity = "guest";
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
      "ttyS0"
      "tty2"
      "tty3"
      "tty4"
      "tty5"
    ];
  };

  services.seatd.enable = true;
  services.greetd = {
    enable = true;
    settings = {
      vt = 6;
      initial_session = {
        user = "guest";
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
              echo "guest:$2" | ${pkgs.shadow}/bin/chpasswd
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

  # Use less privileged guest user
  users.users.guest = {
    uid = 1000;
    isNormalUser = true;
    group = "users";
    createHome = true;
    home = "/home/guest";
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
  nix.settings.trusted-users = [ "guest" ];

  # We run sshd by default. Login is only possible after adding a
  # password via "passwd" or by adding a ssh key to ~/.ssh/authorized_keys.
  # The latter one is particular useful if keys are manually added to
  # installation device for head-less systems i.e. arm boards by manually
  # mounting the storage in a different system.
  services.openssh = {
    enable = lib.mkDefault true;
    settings.PermitRootLogin = lib.mkDefault "yes";
  };

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

  hardware.console.keyMap = "us";

  # Make firmware available.
  hardware.firmware = [ pkgs.linux-firmware ];

  system.synit.enable = true;

  #system.image.extRoot.enable = true;
}
