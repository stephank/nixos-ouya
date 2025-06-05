# Various overrides to reduce the size of the build.

final: prev: {

  openssh = prev.openssh.override {
    withSecurityKey = false;
    withFIDO = false;
  };

}
