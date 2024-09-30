#!/usr/bin/env bash
# Wrapper script for nixos-rebuild

# Configuration parameters
operation="switch"		# The nixos-rebuild operation to use
hostname=$(hostname)	# The name of the host to build
flakeDir="${FLAKE_DIR}"	# Path to the flake file (and optionally the hostname). Defaults to the FLAKE_DIR environment variable.
remainingArgs=""		# All remaining arguments that haven't been processed
update=true				# Whether to update git (true by default)
user=$(whoami)		    # Which user account to use for git commands.

function usage() {
	echo "nixos-rebuild Operations Script (NOS) updates your system and your flake.lock file by pulling the latest versions."
	echo ""
	echo "Running the script with no parameters performs the following operations:"
	echo "  1. Pull the latest version of the config"
	echo "  2. Update your flake.lock file"
	echo "  3. Commit any changes back to the repository"
	echo "  4. Run 'nixos-rebuild switch'."
	echo ""
	echo "Advanced usage: nixos-upgrade-script.sh [-o|--operation operation] [-f|--flake path-to-flake] [extra nixos-rebuild parameters]"
	echo "Options:"
	echo " -h, --help          Show this help screen."
	echo " -o, --operation     The nixos-rebuild operation to perform."
	echo " -f, --flake <path>  The path to your flake.nix file (and optionally, the hostname to build)."
	echo " -n, --no-update     Don't update and commit the lock file."
	echo " -u, --user          Which user account to run git commands under."
	echo ""
	exit 2
}

function run_operation {
	options="--flake $flakeDir $remainingArgs --use-remote-sudo --log-format multiline-with-logs"
	
	echo "Running this operation: nixos-rebuild $1 $options"
	nixos-rebuild $operation $options
} 

# Argument processing logic shamelessly stolen from https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash
POSITIONAL_ARGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
	--flake|-f)
		flakeDir="$2"
		shift
		shift
		;;
	--no-update|-n)
		update=false
		shift
		shift
		;;
	--operation|-o)
		operation="$2"
		shift
		shift
		;;
	--user|-u)
		user="$2"
		shift
		shift
		;;
	--help|-h)
		usage
		shift
		;;
	*)
		POSITIONAL_ARGS+=("$1") # save positional arg
      	shift # past argument
		;;
	esac
done
remainingArgs=${POSITIONAL_ARGS[@]}
set -- "${POSITIONAL_ARGS[@]}" # restore positional parameters

if [ -z "${flakeDir}" ]; then
	echo "Flake directory not specified. Use '--flake <path>' or set \$FLAKE_DIR."
	exit 1
fi

cd $flakeDir

echo "Pulling the latest version of the repository..."
sudo -u $user git pull

if [ $update = true ]; then
	echo "Checking for updates..."
	sudo -u $user nix flake update --commit-lock-file
	sudo -u $user git push
else
	echo "Skipping 'nix flake update'..."
fi

run_operation $operation

exit 0