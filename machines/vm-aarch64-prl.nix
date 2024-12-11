{ config, pkgs, lib, modulesPath, ... }: {
  imports = [
    # Parallels is qemu under the covers. This brings in important kernel
    # modules to get a lot of the stuff working.
    (modulesPath + "/profiles/qemu-guest.nix")

    ./hardware/vm-aarch64-prl.nix
    # ../modules/parallels-guest.nix
    ./vm-shared.nix
  ];

  # Turn this on when the parallels tools work - comment out when it's failing
  hardware.parallels.enable = true;
  # And eliminate this when parallels tools work again
  # disabledModules = [ "virtualisation/parallels-guest.nix" ];

  # Interface is this on my M2
  networking.interfaces.enp0s5.useDHCP = true;

  # Lots of stuff that uses aarch64 that claims doesn't work, but actually works.
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowUnsupportedSystem = true;
}
