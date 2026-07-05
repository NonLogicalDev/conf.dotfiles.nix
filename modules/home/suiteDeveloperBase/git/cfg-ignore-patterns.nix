[
  # Editor/project metadata. These are global ignores because they are almost
  # never meaningful source files in repos this profile works on.
  ".vscode/"
  ".idea/"
  "*.local.md"
  ".nvim.lua"

  # Vim swap/undo/session leftovers.
  "[._]*.s[a-w][a-z]"
  "[._]s[a-w][a-z]"
  "*.un~"
  "Session.vim"
  ".netrwhist"
  "*~"

  # JetBrains and common generated build output.
  "*.iml"
  "*.ipr"
  "*.iws"
  "/out/"
  ".idea_modules/"

  # Old Android/Crashlytics generated files that should not appear as source
  # changes when touching legacy mobile projects.
  "atlassian-ide-plugin.xml"
  "com_crashlytics_export_strings.xml"
  "crashlytics.properties"
  "crashlytics-build.properties"

  # macOS Finder, metadata, trash, Spotlight, and Time Machine noise. These are
  # global because they can appear in any checkout on macOS.
  "*.DS_Store"
  ".AppleDouble"
  ".LSOverride"
  "Icon"
  "._*"
  ".DocumentRevisions-V100"
  ".fseventsd"
  ".Spotlight-V100"
  ".TemporaryItems"
  ".Trashes"
  ".VolumeIcon.icns"
  ".com.apple.timemachine.donotpresent"
  ".AppleDB"
  ".AppleDesktop"
  "Network Trash Folder"
  "Temporary Items"
  ".apdisk"
]
