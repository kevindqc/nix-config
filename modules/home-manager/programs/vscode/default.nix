{ pkgs, ... }:
{
  # Install vscode via home-manager module
  programs.vscode = {
    enable = true;
    package = pkgs.vscode;
  };

  # Enable catppuccin theming for vscode
  catppuccin.vscode.profiles.default.enable = true;
}
