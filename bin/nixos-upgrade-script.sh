#!/usr/bin/env bash
# Wrapper script for nixos-rebuild

#set -e

# Configuration parameters
operation="switch"		# The nixos-rebuild operation to use
hostname=$(hostname)	# The name of the host to build
flakeDir="."					# Path to the flake file (and optionally the hostname)
remainingArgs=""			# All remaining arguments that haven't been processed
commit=true						# Whether to update git (true by default)
buildHost=""					# Which host to build the system on.

function usage() {
	echo "Usage: nixos-upgrade-script.sh [-o|--operation operation] [-f|--flake path-to-flake-file] [extra nixos-rebuild parameters]"
	echo "Options:"
	echo "	-h | --help	Show this help screen."
	echo "	-o | --operation	The nixos-rebuild operation to perform."
	echo "	-H | --host	The host to build."
	echo "  -f | --flake <path>	The path to the flake file (and optionally the hostname)."
	echo "  -n | --no-commit Don't update and commit the lock file."
	echo "  --build-host <hostname> The SSH name of the host to build the system on."
	exit 2
}

function run_operation {
	echo "Full operation: nixos-rebuild $1 --flake $flakeDir#$hostname $( [ "$buildHost" != "" ] && echo "--build-host $buildHost" ) $remainingArgs"

	# Only request super-user permission if we're switching
	if [[ "$1" =~ ^(switch|boot|test)$ ]]; then
		sudo nixos-rebuild $operation --flake .#$hostname $remainingArgs
	else
		nixos-rebuild $operation --flake .#$hostname $remainingArgs
	fi
} 

# Argument processing logic shamelessly stolen from https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash
POSITIONAL_ARGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
	--build-host|-b)
		buildHost="$2"
		shift
		shift
		;;
	--host|--hostname|-H)
		hostname="$2"
		shift
		shift
		;;
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

cd $flakeDir
git pull

if [ $commit = true ]; then
	echo "Update and push lock file"
	nix flake update --commit-lock-file
	git push
fi

# If this is a remote build, run the build as non-sudo first
if [[ "$buildHost" != "" ]]; then
	run_operation "build"
fi

run_operation $operation

exit 0
