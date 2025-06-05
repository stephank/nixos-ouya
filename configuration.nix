{ config, lib, pkgs, modulesPath, ... }:
let
  vars = import ./vars.nix;
in
{

  # Cross-compile to our target.
  nixpkgs.buildPlatform = builtins.currentSystem;
  nixpkgs.hostPlatform = "armv7l-linux";

  # Reduce build size.
  nixpkgs.overlays = [
    (import ./overlay.nix)
  ];

  # Custom kernel. To keep build times low, this doesn't include every driver
  # under the sun, but should be fairly complete. (Otherwise just enable stuff
  # as needed.)
  boot.kernelPackages = pkgs.linuxPackages_custom {
    inherit (pkgs.linux_latest) version src;
    configfile = ./kernel_config;
  };
  boot.kernelParams = [
    # Tegra Android devices use a custom partition table, but do include a
    # mirror GPT at the end of eMMC. This option is necessary for Linux to
    # pick up on that alternative GPT location.
    "gpt"
    # Useful for debugging.
    "boot.shell_on_fail"
  ];
  boot.initrd = {
    # We compile in most drivers we need. The default modules are not present.
    includeDefaultModules = false;
    # We set only CONFIG_RD_XZ.
    compressor = "xz";
  };

  # The root device can be empty, but is intended to hold all state.
  # We just need the (immutable) Nix store from the squashfs to get going.
  fileSystems = {
    "/" = {
      device = vars.rootDevice;
      fsType = "ext4";
      neededForBoot = true;
    };
    "/boot/system" = {
      device = vars.squashfsContainerDevice;
      fsType = "ext4";
      options = [ "ro" ];
      neededForBoot = true;
    };
    "/nix/store" = {
      device = "/boot/system${vars.squashfsPath}";
      fsType = "squashfs";
      options = [ "ro" ];
      depends = [ "/boot/system" ];
      neededForBoot = true;
    };
  };

  system.stateVersion = "25.05";

  # Keep limited logs in memory.
  services.journald.storage = "volatile";

  # Prefer networkd. Don't need a firewall.
  # NixOS configures DHCP for ethernet interfaces by default.
  networking = {
    hostName = "ouya";
    useNetworkd = true;
    firewall.enable = false;
  };

  # Disable root login. Configure a regular user for login.
  users = {
    mutableUsers = false;
    users = {
      root.hashedPassword = null;
      ouya = {
        isNormalUser = true;
        extraGroups = [ "wheel" ];
        hashedPassword = vars.hashedPassword;
        openssh.authorizedKeys.keys = vars.sshPublicKeys;
      };
    };
  };

  # Allow sudo for the regular user.
  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
    execWheelOnly = true;
  };

  # SSH access.
  services.openssh.enable = true;

  # Flags for system and Nix store immutability.
  system.switch.enable = false;
  system.disableInstallerTools = true;
  nix.enable = false;

  # Further reduce size of the rootfs.
  environment.defaultPackages = lib.mkForce [ ];
  boot.enableContainers = false;
  services.lvm.enable = false;
  documentation = {
    enable = false;
    man.enable = false;
    info.enable = false;
    doc.enable = false;
    nixos.enable = false;
  };

  # We don't need GRUB.
  boot.loader.grub.enable = false;
  # If you are brave and flashed U-Boot to your device. But you'll also have
  # to change the type of image output. Exercise for the reader.
  #boot.loader.generic-extlinux-compatible.enable = true;

  # Squashfs containing the Nix store.
  system.build.image = pkgs.callPackage "${modulesPath}/../lib/make-squashfs.nix" {
    fileName = "system";
    storeContents = [ config.system.build.toplevel ];
    # Additional symlink to point to the system build.
    pseudoFiles = [
      "_system s 0755 0 0 ${builtins.baseNameOf config.system.build.toplevel}"
    ];
  };

}
