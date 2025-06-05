# NixOS on Ouya

Status: EXPERIMENTAL

This repo contains a [NixOS] system you can flash to your old [Ouya] console.

[NixOS]: https://nixos.org/
[Ouya]: https://en.wikipedia.org/wiki/Ouya

# Usage

This assume you have an Ouya with [Ouya Bootmenu] installed. This is a safe,
software-only method to boot custom firmware, without 'bricking' your Ouya.
(These days, you can [unbrick your Ouya], but it requires some light hardware
tinkering.)

[Ouya Bootmenu]: https://xdaforums.com/t/bootloader-safeboot-ouya-bootmenu-mlq.2692836/
[unbrick your Ouya]: https://github.com/tofurky/tegra30_debrick

The NixOS image can be cross-compiled from any Linux system (or VM).
Take a look at `vars.nix` for some basic settings, and edit as needed.
Then just [install Lix or Nix], checkout this repository, and run:

```sh
nix-build
```

[install Lix or Nix]: https://lix.systems/install/

The results will be in `result/boot.img` and `result/system.squashfs`. You can
place `boot.img` in one of the locations expected by Ouya Bootmenu
(`/sdcard/altboot.img` or `/system/boot.img`), and `system.squashfs` in the
expected location per `vars.nix`.

# Implementation

Ouya Bootmenu uses a trick called 'kexec hardboot', which works a bit like
kexec, but actually resets the hardware. The Linux kernel in Ouya Bootmenu has
special early startup code that switches to a different kernel (your target).

This trick was necessary for the older Linux kernels used in Ouya, but the
hardware is nowadays supported in mainline Linux, and regular kexec works.

So instead, we use a regular mainline kernel here as a sort of second-stage
bootloader. This is the resulting `boot.img`, built by `bootloader.nix`.
This mounts our actual NixOS image from squashfs, then does a normal kexec.

The `/nix/store` in the final system is immutable, so to add functionality,
you need to further tweak `configuration.nix` and reflash `system.squashfs`.
