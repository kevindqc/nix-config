{ nhModules, pkgs, ... }:
{
  imports = [
    "${nhModules}/common"
    "${nhModules}/desktop/kde"
  ];

  # Enable home-manager
  programs.home-manager.enable = true;

  # User packages
  home.packages = with pkgs; [
    radeontop
  ];

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "25.05";
}
