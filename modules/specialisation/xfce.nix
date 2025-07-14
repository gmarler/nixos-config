# xfce (X11)
{ pkgs, ... }: {
  specialisation.xfce.configuration = {
    # We need an XDG portal for various applications to work properly,
    # such as Flatpak applications.
    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
      config.common.default = "*";
    };

    services = {
      xserver = {
        enable = true;
        xkb.layout = "us";
        dpi = 220;

        displayManager = {
          lightdm.enable = true;
        };

        desktopManager = {
          xfce.enable = true;
          # wallpaper.mode = "fill";
        };
      };

      displayManager = {
        autoLogin.enable = true;
        autoLogin.user = "gmarler";
      };

      # Nice graphical effects - not required
      picom = {
        enable = true;
        fade = true;
        inactiveOpacity = 0.9;
        shadow = true;
        fadeDelta = 4;
      };
    };
  };
}
