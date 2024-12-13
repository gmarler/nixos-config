{ config, pkgs, lib, modulesPath, ... }: {
  imports = [
    # Parallels is qemu under the covers. This brings in important kernel
    # modules to get a lot of the stuff working.
    (modulesPath + "/profiles/qemu-guest.nix")

    ./hardware/vm-aarch64-prl.nix
    # ../modules/parallels-guest.nix
    ./vm-shared.nix
  ];

  # Also derived in part from: https://github.com/wegank/nixos-config/blob/main/hardware/parallels/hardware-configuration.nix

  hardware.parallels = {
    # Turn this on when the parallels tools work - comment out when it's failing
    enable = true;
    # And eliminate this when parallels tools work again
    # disabledModules = [ "virtualisation/parallels-guest.nix" ];

    # If you have to patch prl-tools, here's what needs specifying
    package = config.boot.kernelPackages.prl-tools.overrideAttrs (
      finalAttrs: previousAttrs: {
        version = "20.1.1-55740";
        src = previousAttrs.src.overrideAttrs {
          outputHash = "sha256-3Lo/tAPn3vYvHXV9r8VeMkxKjRPpr8fhADh0vyppC0k=";
        };
        patches = [
          ./prl-tools-linux-6.12.patch
        ];
      }
    );
  };

  # Interface is this on my M2
  networking.interfaces.enp0s5.useDHCP = true;

  # Lots of stuff that uses aarch64 that claims doesn't work, but actually works.
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowUnsupportedSystem = true;
}
