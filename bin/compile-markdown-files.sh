#!/usr/bin/env bash
# Script to compile Markdown files within a directory into various output formats.
# Based on https://github.com/8bitbuddhist/markdown-novel-template

draftName="draft"
directory="."

function usage() {
	echo "Compile a directory of Markdown (.md) files into DOCX, ePub, and PDF files."
	echo ""
	echo "Options:"
	echo " --help                       Show this help screen."
	echo " -n, --name [name]            The name of this draft."
	echo " -d, --directory [path]       Where to store the output files."
	echo ""
	exit 0
}

# Argument processing logic shamelessly stolen from https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash
POSITIONAL_ARGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
	--draft-name|--name|-n)
		name="$2"
		shift
		shift
		;;
	--directory|--dir|-d)
		directory="$2"
		shift
		shift
		;;
	--help)
		usage
		;;
	*)
		POSITIONAL_ARGS+=("$1") # save positional arg
		shift
		;;
	esac
done
remainingArgs=${POSITIONAL_ARGS[@]}
set -- "${POSITIONAL_ARGS[@]}" # restore positional parameters

# If this is a git repo, name the draft after the current branch
if [ -d ".git" ]; then
	draft=$(git rev-parse --abbrev-ref HEAD)
fi

# Check if this directory already exists
if [ -d "drafts/${draft}" ]; then
	echo "This folder already exists. Type YES to overwrite"
	read confirm && [[ $confirm == [YES] ]] || exit 1
fi

draftFile="drafts/${draft}/${draft}"

echo "Compiling draft \"${draft}\"..."

# Create the draft directory if it doesn't already exist
mkdir -p drafts/${draft}

# Initialize merged file
echo > $draftFile.md

# Grab content files and add a page break to the end of each one.
# Obsidian specifically creates "folder notes," which are named for the directory, so we make sure to exclude it.
find $directory/*.md ! -name $directory.md -print0 | sort -z | while read -d $'\0' file
do
	# Add newline to Markdown doc
	echo >> $draftFile.md
	# Clean up incoming Markdown and append it to final doc
	sed '/%% Begin Waypoint %%/,/%% End Waypoint %%/d' $file >> $draftFile.md
	echo "\\newpage" >> $draftFile.md
done

# Generate the output files:
#		Markdown -> DOCX
#		Markdown -> EPUB
#		Markdown -> PDF (A4 size)
#		Markdown -> PDF (B6/Standard book size)
pandoc -t docx $draftFile.md -o $draftFile.docx --metadata-file metadata.yml
pandoc -t epub $draftFile.md -o $draftFile.epub --metadata-file metadata.yml
pandoc $draftFile.md -o ${draftFile}-a4.pdf --metadata-file metadata.yml -V geometry:"a4paper" -V fontsize:"12pt"
pandoc $draftFile.md -o ${draftFile}-b6.pdf --metadata-file metadata.yml -V geometry:"b6paper" -V fontsize:"10pt"

echo "Done! Your new draft is in ${PWD}/drafts/${draft}/"
