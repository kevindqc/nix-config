{
  inputs,
  outputs,
  lib,
  config,
  userConfig,
  pkgs,
  ...
}:
{
  # Nixpkgs configuration
  nixpkgs = {
    overlays = [
      outputs.overlays.stable-packages
    ];

    config = {
      allowUnfree = true;
    };
  };

  # Register flake inputs for nix commands
  nix.registry = lib.mapAttrs (_: flake: { inherit flake; }) (
    lib.filterAttrs (_: lib.isType "flake") inputs
  );

  # Add inputs to legacy channels
  nix.nixPath = [ "/etc/nix/path" ];
  environment.etc = lib.mapAttrs' (name: value: {
    name = "nix/path/${name}";
    value.source = value.flake;
  }) config.nix.registry;

  # Nix settings
  nix.settings = {
    experimental-features = "nix-command flakes";
    auto-optimise-store = true;
  };

  # Boot settings
  boot = {
    kernelPackages = pkgs.linuxKernel.packages.linux_6_17;
    consoleLogLevel = 0;
    initrd.verbose = false;
    kernelParams = [
      "quiet"
      "splash"
      "rd.udev.log_level=3"
    ];
    loader.efi.canTouchEfiVariables = true;
    loader.systemd-boot.enable = false;
    loader.grub = {
      enable = true;
      efiSupport = true;
      devices = [ "nodev" ];
      useOSProber = true;
      extraEntries = ''
  menuentry 'Kubuntu' --class kubuntu --class gnu-linux --class gnu --class os \$menuentry_id_option 'gnulinux-simple-9668003d-6dd9-4e34-909e-bceb82f6121d' {
      recordfail
      load_video
      gfxmode \$linux_gfx_mode
      insmod gzio
      if [ x\$grub_platform = xxen ]; then insmod xzio; insmod lzopio; fi
      insmod part_gpt
      insmod btrfs
      search --no-floppy --fs-uuid --set=root 9668003d-6dd9-4e34-909e-bceb82f6121d
      linux /@/boot/vmlinuz-6.14.0-34-generic root=UUID=9668003d-6dd9-4e34-909e-bceb82f6121d ro rootflags=subvol=@ quiet splash resume=UUID=56c5722e-c765-4777-8103-32f6474bcdc6 pcie_port_pm=off pcie_aspm.policy=performance amdgpu.ppfeaturemask=0xffffffff \$vt_handoff
      initrd /@/boot/initrd.img-6.14.0-34-generic
  }
'';

    };
    loader.timeout = 10;
    plymouth.enable = true;

    # v4l (virtual camera) module settings
    kernelModules = [ "v4l2loopback" ];
    extraModulePackages = with config.boot.kernelPackages; [ v4l2loopback ];
    extraModprobeConfig = ''
      options v4l2loopback exclusive_caps=1 card_label="Virtual Camera"
    '';
  };

  # Networking
  networking.networkmanager.enable = true;

  # Disable systemd services that are affecting the boot time
  systemd.services = {
    NetworkManager-wait-online.enable = false;
    plymouth-quit-wait.enable = false;
  };

  # Timezone
  time.timeZone = "America/Toronto";

  # Internationalization
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_CA.UTF-8";
    LC_IDENTIFICATION = "en_CA.UTF-8";
    LC_MEASUREMENT = "en_CA.UTF-8";
    LC_MONETARY = "en_CA.UTF-8";
    LC_NAME = "en_CA.UTF-8";
    LC_NUMERIC = "en_CA.UTF-8";
    LC_PAPER = "en_CA.UTF-8";
    LC_TELEPHONE = "en_CA.UTF-8";
    LC_TIME = "en_CA.UTF-8";
  };

  # Enables support for Bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  # Input settings
  services.libinput.enable = true;

  # xserver settings
  services.xserver = {
    xkb.layout = "en";
    xkb.variant = "";
    excludePackages = with pkgs; [ xterm ];
  };

  # Enable Wayland support in Chromium and Electron based applications
  # Remove decorations for QT apps
  # Set cursor size
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    XCURSOR_SIZE = "24";
  };

  # PATH configuration
  environment.localBinInPath = true;

  # Disable CUPS printing
  services.printing.enable = false;

  # Enable devmon for device management
  services.devmon.enable = true;

  # Enable PipeWire for sound
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # Enable flatpak service
  services.flatpak.enable = true;

  # User configuration
  users.users.${userConfig.name} = {
    description = userConfig.fullName;
    extraGroups = [
      "input"
      "networkmanager"
      "wheel"
    ];
    isNormalUser = true;
    shell = pkgs.zsh;
  };

  # Set User's avatar
  system.activationScripts.script.text = ''
    mkdir -p /var/lib/AccountsService/{icons,users}
    cp ${userConfig.avatar} /var/lib/AccountsService/icons/${userConfig.name}

    touch /var/lib/AccountsService/users/${userConfig.name}

    if ! grep -q "^Icon=" /var/lib/AccountsService/users/${userConfig.name}; then
      if ! grep -q "^\[User\]" /var/lib/AccountsService/users/${userConfig.name}; then
        echo "[User]" >> /var/lib/AccountsService/users/${userConfig.name}
      fi
      echo "Icon=/var/lib/AccountsService/icons/${userConfig.name}" >> /var/lib/AccountsService/users/${userConfig.name}
    fi
  '';

  # Passwordless sudo
  security.sudo.wheelNeedsPassword = false;

  # System packages
  environment.systemPackages = with pkgs; [
    gcc
    glib
    gnumake
    input-remapper
    killall
    mesa
  ];

  # Common container config
  virtualisation = {
    containers.enable = true;
    podman = {
      enable = true;
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  # Enable xwayland
  programs.xwayland.enable = true;

  # Zsh configuration
  programs.zsh.enable = true;

  # Fonts configuration
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.meslo-lg
    roboto
  ];

  # Additional services
  services.locate.enable = true;

  # OpenSSH daemon
  services.openssh.enable = true;
}
