{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    lutris
    wineWowPackages.full
    winetricks
    vulkan-tools
    mangohud
  ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
}