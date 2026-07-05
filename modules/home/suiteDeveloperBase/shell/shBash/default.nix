{
  # Bash is not the primary interactive shell for this host-user profile.
  # Enabling it here still matters because `programs.unmanaged.bash` can then
  # copy Home Manager's generated Bash profile/bashrc content into the numbered
  # hook layout used by mutable top-level shell files.
  programs.bash.enable = true;
}
