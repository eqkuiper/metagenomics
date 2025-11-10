#!/usr/bin/env bash
# This script is for downloading FASTA files from NCBI using accession numbers which often start with GCA/GFA + a bunch of numbers. It often misses files but that's not the script's fault, so if you have a lot of files, make sure to double check your downloads.
#1 Take this script to a directory where you wan't to download your genomes/fasta files. 
#2 Edit file and folder names wherever there are comments to do so. 
#3 Save and run it using the following command:
# nohup ./download_fastas.sh accessions.txt subsurface_fastas > download.log 2>&1 &
# The command runs on nohup, which means after it starts running, you can log out or shut down your computer. The script will keep running and output a log file and a folder with all fasta files. 
set -euo pipefail

ACC_FILE="${1:-data/MOBs_ncbi_refseqs/MOB_total_list.txt}" #accessions.txt has to exist in your working directory. 
OUT_DIR="${2:-data/MOBs_ncbi_refseqs/reference_fasta}" #this would be created
mkdir -p "$OUT_DIR"

# Activate environment (optional)
if command -v conda >/dev/null 2>&1; then
  eval "$(conda shell.bash hook)" || true
  conda activate /projects/p32449/goop_stirrers/miniconda3/envs/ncbi_datasets || true     #you will have install NCBI tools in your allocation and give a path to that here. it's a conda installation; so not that deep: https://anaconda.org/conda-forge/ncbi-datasets-cli
fi

# YOU PROBABLY DON'T NEED THIS: Canonicalize accessions (make uppercase, extract GCA_/GCF_ pattern)
canonicalize() {
    echo "$1" | tr '[:lower:]' '[:upper:]' | grep -oE 'GC[AF]_[0-9]+\.[0-9]+' || true
}

while IFS= read -r line; do
  [[ -z "$line" || "$line" == accession* ]] && continue
  acc=$(canonicalize "$line")
  [[ -z "$acc" ]] && { echo "Skipping invalid accession: $line"; continue; }

  # Skip if already downloaded
  if [[ -s "$OUT_DIR/$acc.fna" ]]; then
    echo "⏭️  Skipping $acc (already exists)"
    continue
  fi

  echo "⬇️  Downloading $acc ..."
  datasets download genome accession "$acc" --include genome --filename "$OUT_DIR/$acc.zip" || {
    echo "⚠️  Schist! Failed to download $acc"
    continue
  }

  unzip -q "$OUT_DIR/$acc.zip" -d "$OUT_DIR/$acc"
  rm "$OUT_DIR/$acc.zip"

  
  # Move all .fna files to flat folder
  find "$OUT_DIR/$acc" -type f -name "*.fna" -exec mv {} "$OUT_DIR/$acc.fna" \; || true
  rm -rf "$OUT_DIR/$acc"
  echo "✅  Saved $OUT_DIR/$acc.fna"

  sleep 0.3
done < "$ACC_FILE"

echo "🎉 YOOOOOO Done (Probably)! FASTA files saved in: $OUT_DIR. Don't forget to double check"

#If you see some files missing or see that the download.log file has error mesages ⚠️, just run the following line in the same folder as a your download.log to extract all the accession numbers that didn't get downloaded in the first try.
# grep "Failed to download" download.log | grep -oE 'GC[AF]_[0-9]+\.[0-9]+' > failed_accessions.txt
# Then you can modify this script to use failed_accessions.txt as your accessions.txt


