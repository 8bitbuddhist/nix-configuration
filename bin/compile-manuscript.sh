#!/usr/bin/env bash
# Script to compile Markdown files within a directory into various output formats.
# Based on https://github.com/8bitbuddhist/markdown-novel-template

draftName="draft"
inDir="."
outDir="./out"
metadataFile="$inDir/metadata.yml"

function usage() {
  echo "Compile a directory of Markdown (.md) files into DOCX, ePub, and PDF files."
  echo ""
  echo "Options:"
  echo " --help                       Show this help screen."
  echo " -n, --name [name]            The name of this draft."
  echo " -i, --input [path]           Directory containing the files to convert. Defaults to this directory."
  echo " -o, --output [path]          Directory to store the converted files in. Defaults to ./out."
  echo " -m, --metadata [path]        Path to the YAML file containing metadata for pandoc."
  echo ""
  exit 0
}

# Argument processing logic shamelessly stolen from https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash
POSITIONAL_ARGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --draft-name|--name|-n)
      draftName="$2"
      shift
      shift
      ;;
    --input|--indir|-i)
      inDir="$2"
      shift
      shift
      ;;
    --output|--outdir|-o)
      outDir="$2"
      shift
      shift
      ;;
    --metadata|--metadataFile|-m)
      metadataFile="$2"
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
set -- "${POSITIONAL_ARGS[@]}" # restore positional parameters

# If this is a git repo and no name has been provided, name the draft after the current branch
if [ -d ".git" ] && [ "$draftName" = "draft" ]; then
  draftName=$(git rev-parse --abbrev-ref HEAD)
fi

# Check if this directory already exists
outDir="$outDir/${draftName}"
if [ -d "$outDir" ]; then
  echo "The folder $outDir already exists."
  read -rp "Enter YES to overwrite, or Ctrl-C to cancel: " confirm && [ "$confirm" = "YES" ] || exit 1
fi

draftFile="$outDir/${draftName}"

echo "Compiling draft \"${draftName}\"..."

# Create the draft directory if it doesn't already exist
mkdir -p "$outDir"

# Initialize merged file
echo > "$draftFile".md

# Grab content files and add a page break to the end of each one.
# Obsidian specifically creates "folder notes," which are named for the directory, so we make sure to exclude it.
find "$inDir" -type f -wholename "**.md" ! -name content.md -print0 | sort -z | while read -rd $'\0' file
do
  # Add newline to Markdown doc
  echo >> "$draftFile".md
  # Clean up incoming Markdown and append it to final doc
  sed "s|(../|($inDir/../|g" "$file" >> "$draftFile".md
  echo "\\newpage" >> "$draftFile".md
done

# Generate the output files:
#		Markdown -> DOCX
#		Markdown -> EPUB
#		Markdown -> PDF (A4 size)
#		Markdown -> PDF (B6/Standard book size)
pandoc -t docx "$draftFile".md -o "$draftFile".docx --metadata-file "$metadataFile"
pandoc -t epub "$draftFile".md -o "$draftFile".epub --metadata-file "$metadataFile"
pandoc "$draftFile".md -o "$draftFile"-a4.pdf --metadata-file "$metadataFile" -V geometry:"a4paper" -V fontsize:"12pt"
pandoc "$draftFile".md -o "$draftFile"-b6.pdf --metadata-file "$metadataFile" -V geometry:"b6paper" -V fontsize:"10pt"

echo "Done! Your new draft is in $outDir"
