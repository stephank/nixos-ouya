let

  # Pinned Nixpkgs. (Could also use flakes / niv / npins, if preferred.)
  nixpkgs = builtins.fetchTarball {
    url = "https://releases.nixos.org/nixpkgs/nixpkgs-25.11pre809757.e4b09e47ace7/nixexprs.tar.xz";
    sha256 = "0y6cwwb65ca1pnqng8fi1d6lr96vmp7gdb7gyxg0vl6qfykc8m41";
  };

  # Evaluate the NixOS configuration.
  eval = import "${nixpkgs}/nixos" {
    configuration = ./configuration.nix;
  };
  inherit (eval) config pkgs system;

  # Our custom third-stage bootloader for Ouya Bootmenu.
  bootloader = pkgs.callPackage ./bootloader.nix { };

in
  # Combined output directory.
  pkgs.runCommand "output" { } ''
    mkdir $out
    # Place these in /system on Ouya. (with e.g. `adb push`)
    ln -s '${bootloader}' $out/boot.img
    ln -s '${config.system.build.image}' $out/system.squashfs
    # For inspecting the build result.
    ln -s '${system}' $out/system
  ''
