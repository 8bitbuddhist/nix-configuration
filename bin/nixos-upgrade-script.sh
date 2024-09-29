#!/usr/bin/env bash
# Wrapper script for nixos-rebuild

# Configuration parameters
operation="switch"		# The nixos-rebuild operation to use
hostname=$(hostname)	# The name of the host to build
flakeDir="."			# Path to the flake file (and optionally the hostname)
remainingArgs=""		# All remaining arguments that haven't been processed
commit=true				# Whether to update git (true by default)

function usage() {
	echo "Usage: nixos-upgrade-script.sh [-o|--operation operation] [-f|--flake path-to-flake-file] [extra nixos-rebuild parameters]"
	echo "Options:"
	echo "	-h | --help	Show this help screen."
	echo "	-o | --operation	The nixos-rebuild operation to perform."
	echo "  -f | --flake <path>	The path to the flake file."
	echo "  -n | --no-commit Don't update and commit the lock file."
	exit 2
}

function run_operation {
	echo "Running this operation: nixos-rebuild $1 --flake $flakeDir $remainingArgs --use-remote-sudo"
	nixos-rebuild $operation --flake $flakeDir $remainingArgs --use-remote-sudo --log-format multiline-with-logs
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
	--no-commit|-n)
		commit=false
		shift
		shift
		;;
	--operation|-o)
		operation="$2"
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

if [ -z "${FLAKE_DIR}" ]; then
	echo "Flake directory not specified. Use '--flake [directory]' or set the $FLAKE_DIR environment variable."
	exit 1
else
	flakeDir=$FLAKE_DIR 
fi

cd $flakeDir

echo "Pulling the latest version of the repository..."
git pull

if [ $commit = true ]; then
	echo "Checking for updates..."
	nix flake update --commit-lock-file
	git push
fi

run_operation $operation

exit 0
