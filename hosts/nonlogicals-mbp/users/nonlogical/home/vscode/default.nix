{ ... }:

{
  # Preserve the already deployed XDG settings. Do not take over a separate
  # macOS Library/Application Support profile or reinstall the editor.
  xdg.configFile."Code/User/settings.json".source = ./settings.json;
}
