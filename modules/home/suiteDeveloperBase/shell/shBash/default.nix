{
  # Bash is not the primary interactive shell for this host-user profile.
  # Enabling it here still matters because `programs.unmanaged.bash` can then
  # copy Home Manager's generated Bash profile/bashrc content into the numbered
  # hook layout used by mutable top-level shell files. That includes ~/.profile:
  # native Home Manager bash would make it an immutable store symlink, while the
  # unmanaged bridge converts that symlink into a regular file and maintains
  # only the marked dispatcher source block inside it.
  programs.bash.enable = true;
  programs.unmanaged.bash.enable = true;
}
