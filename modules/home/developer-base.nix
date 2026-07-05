{ ... }:

{
  # Blueprint exports top-level files in `modules/home/` as `homeModules.*`.
  # The actual suite lives under `suites/` to keep the repo layout honest, while
  # this thin wrapper gives host-user profiles a stable flake output to import.
  imports = [ ./suites/developer-base ];
}
