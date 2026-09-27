{ ... }:

{
  programs.vifm = {
    enable = true;
    extraConfig = builtins.readFile ./vifmrc;
  };

  # Manage only configuration: vifminfo and trash remain mutable user data.
  xdg.configFile = {
    "vifm/colors".source = ./colors;
    "vifm/scripts" = {
      source = ./scripts;
      recursive = true;
      executable = true;
    };
  };
}
