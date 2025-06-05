{
  # Storage layout.
  squashfsContainerDevice = "/dev/mmcblk0p3"; # APP (/system)
  squashfsPath = "/system.squashfs";
  rootDevice = "/dev/mmcblk0p9"; # UDA (/data)

  # Some alternative ideas:
  #squashfsContainerDevice = "/dev/mmcblk0p9"; # UDA (/data)
  #squashfsPath = "/nixos.squashfs";
  #rootDevice = "/dev/sda1"; # USB stick

  # For logging in to the 'ouya' user account.
  # Example hash is for: 0uyaOUYA
  hashedPassword = "$y$j9T$uU/1mmPPX7nLD/U5xEuxQ/$PCbluzGcaq1zI0tsEJifXpRw/Tt3HTev8YnaePRYgcC"; 
  sshPublicKeys = [ ];
}
