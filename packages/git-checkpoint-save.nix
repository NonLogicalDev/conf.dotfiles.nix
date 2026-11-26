{ pkgs, pname, ... }:

pkgs.writeShellApplication {
  name = pname;
  runtimeInputs = [
    pkgs.coreutils
    pkgs.git
  ];

  text = ''
    usage() {
      printf 'Usage: git-checkpoint-save [--role ROLE] [--all] [--subject-only] [NOTE]\n' >&2
      exit 2
    }

    role=manual
    note=
    has_note=false
    stage_all=false
    subject_only=false
    while [ "$#" -gt 0 ]; do
      case "$1" in
        --role)
          [ "$#" -ge 2 ] || usage
          role=$2
          case "$role" in
            ""|-*) usage ;;
          esac
          shift
          ;;
        --all)
          stage_all=true
          ;;
        --subject-only)
          subject_only=true
          ;;
        -*)
          usage
          ;;
        *)
          [ "$has_note" = false ] || usage
          note=$1
          has_note=true
          ;;
      esac
      shift
    done

    if [ -z "$note" ]; then
      note=$(date '+%Y-%d-%mT%H-%M-%S')
    fi
    subject="checkpoint:$role - $note"

    if [ "$subject_only" = true ]; then
      printf '%s\n' "$subject"
      exit 0
    fi

    if [ "$stage_all" = true ]; then
      git add -A
    fi
    exec git commit -m "$subject"
  '';

  meta = {
    description = "Save a local Git checkpoint with a role and optional note";
    mainProgram = pname;
  };
}
