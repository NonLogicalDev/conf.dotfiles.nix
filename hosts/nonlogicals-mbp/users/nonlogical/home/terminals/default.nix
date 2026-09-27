{ ... }:

{
  # Manage terminal preferences independently of application installation.
  # Ghostty is installed already; retain the other profiles for later use.
  programs.ghostty = {
    enable = true;
    package = null;
    settings = {
      adjust-cell-height = -2;
      font-feature = "-calt, -liga, -dlig";
      font-size = 14;
      font-synthetic-style = true;
      cursor-style = "block";
      shell-integration-features = "no-cursor";
      window-inherit-font-size = false;
      selection-invert-fg-bg = true;
      clipboard-read = "ask";
      copy-on-select = "clipboard";
      term = "xterm-256color";
      window-colorspace = "display-p3";
      theme = "TokyoNight Night (custom)";
      background-opacity = 0.90;
      background-opacity-cells = true;
      background-blur = 100;
      keybind = [
        "global:ctrl+grave_accent=toggle_quick_terminal"
        "command+shift+r=reload_config"
        "command+shift+t=text:\\x01c"
        "command+shift+[=text:\\x01p"
        "command+shift+]=text:\\x01n"
        "command+shift+,=text:\\x01<"
        "command+shift+.=text:\\x01>"
        "command+f=text:\\x01[?"
        "command+k>1=text:\\x01>"
        "command+k>2=text:\\x01<"
      ];
    };
  };

  # The former YAML used Alacritty's pre-0.13 schema. Express the same active
  # settings in its current TOML schema; the old reference file is documentation.
  programs.alacritty = {
    enable = true;
    package = null;
    settings = {
      window = {
        dynamic_title = true;
        dimensions = {
          columns = 120;
          lines = 40;
        };
        opacity = 0.99;
      };
      scrolling.history = 100000;
      font = {
        size = 12.0;
        normal = {
          family = "Fixedsys Excelsior";
          style = "Regular";
        };
        bold = {
          family = "Fixedsys Excelsior";
          style = "Regular";
        };
        italic = {
          family = "Fixedsys Excelsior";
          style = "Regular";
        };
      };
      colors = {
        draw_bold_text_with_bright_colors = true;
        primary = {
          background = "#1d1f21";
          foreground = "#c5c8c6";
          dim_foreground = "#828482";
          bright_foreground = "#eaeaea";
        };
        cursor = {
          text = "CellBackground";
          cursor = "CellForeground";
        };
        search = {
          matches = {
            foreground = "#000000";
            background = "#ffffff";
          };
          focused_match = {
            foreground = "#ffffff";
            background = "#000000";
          };
        };
        footer_bar = {
          background = "#c5c8c6";
          foreground = "#1d1f21";
        };
        hints = {
          start = {
            foreground = "#1d1f21";
            background = "#e9ff5e";
          };
          end = {
            foreground = "#e9ff5e";
            background = "#1d1f21";
          };
        };
        line_indicator = {
          foreground = "None";
          background = "None";
        };
        selection = {
          text = "CellBackground";
          background = "CellForeground";
        };
        normal = {
          black = "#111111";
          red = "#cc6666";
          green = "#b5bd68";
          yellow = "#f0c674";
          blue = "#81a2be";
          magenta = "#b294bb";
          cyan = "#8abeb7";
          white = "#c5c8c6";
        };
        bright = {
          black = "#666666";
          red = "#d54e53";
          green = "#b9ca4a";
          yellow = "#e7c547";
          blue = "#7aa6da";
          magenta = "#c397d8";
          cyan = "#70c0b1";
          white = "#eaeaea";
        };
      };
    };
  };

  xdg.configFile = {
    "ghostty/themes".source = ./ghostty/themes;
    # Keep the optional shader available without enabling an inactive effect.
    "ghostty/crt.glsl".source = ./ghostty/crt.glsl;
  };

  # Home Manager's WezTerm module requires installing its package. Keep the
  # existing macOS application and conventional config entrypoint instead.
  home.file.".wezterm.lua".source = ./wezterm.lua;
}
