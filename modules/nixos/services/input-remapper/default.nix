{ ... }:
{
  # Enable input-remapper service
  services.input-remapper = {
    enable = true;
    enableUdevRules = true;
  };

}
