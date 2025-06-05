{
  lib,
  linuxManualConfig,
  linux_latest,
  buildPackages,
  pkgsStatic,
  runCommand,
  cpio,
  xz,
  android-tools,
}:

let
  inherit (buildPackages)
    runCommand runCommandCC replaceVarsWith;

  # Ouya Bootmenu can't handle bootimgs larger than 8MB. Use a smaller kernel
  # as bootloader to kexec the real kernel. Using kexec also gives us control
  # over kernel parameters and device tree.
  kernel = linuxManualConfig {
    inherit (linux_latest) version src;
    allowImportFromDerivation = true;
    configfile = ./bootloader_config;
  };

  init = replaceVarsWith {
    src = ./bootloader.sh;
    replacements = {
      inherit (import ./vars.nix)
        squashfsContainerDevice squashfsPath;
    };
  };

  # Can't mknod in a Nix sandbox. The Linux kernel includes a tool that can
  # generate a cpio archive with device nodes in it. Reuse that to build our
  # bootloader initramfs.
  initrd = runCommandCC "initrd" {
    nativeBuildInputs = [ xz ];
  }
    ''
      tar -xf '${kernel.src}'
      KERNEL_SRC="$(echo $PWD/linux-*)"

      pushd "$KERNEL_SRC/usr/"
      gcc gen_init_cpio.c -o gen_init_cpio
      popd

      cp -R '${pkgsStatic.busybox}' work
      chmod -R u+w work
      cd work
      INITRD_WORK="$PWD"

      rm default.script linuxrc
      install -m 0755 '${init}' ./init
      install -m 0644 ${kernel}/dtbs/tegra30-ouya.dtb ./
      install -m 0755 ${pkgsStatic.kexec-tools}/bin/kexec ./bin/
      mkdir -p proc sys mnt nix/store

      cd "$KERNEL_SRC"
      ./usr/gen_initramfs.sh \
        -o $out -u squash -g squash -d @1 \
        ./usr/default_cpio_list \
        "$INITRD_WORK"
    '';
in
  runCommand
    "boot.img"
    {
      nativeBuildInputs = [ android-tools ];
    }
    ''
      # Append the DTB for CONFIG_ARM_APPENDED_DTB
      cat ${kernel}/zImage ${kernel}/dtbs/tegra30-ouya.dtb > zImage-dtb
      mkbootimg \
        --kernel zImage-dtb \
        --ramdisk '${initrd}' \
        --base 0x10000000 \
        --second_offset 0x00f00000 \
        --kernel_offset 0x00008000 \
        --ramdisk_offset 0x01000000 \
        --tags_offset 0x00000100 \
        --pagesize 2048 \
        -o "$out"
    ''
