#!/usr/bin/sh
# Author: hexpwn (x.com/hexpwn)
# Version: 1
#
# Stupidly naive search for changes in the files of a firmware filesystem.
#
# SRC_DIR and DST_DIR should be the, already mounted, directories of the rootfs
# for each firmware version.
#
# FILE_EXTENSION should be a filetype (ex: .so, .lua, .sh. Omit the period)
# 
# Usage:
#   ./firmdiff.sh [SRC_DIR] [DST_DIR] [FILE_EXTENSION]
#
# Example:
#   ./firmdiff.sh ./ver1.0/rootfs/ ./ver2.0/rootfs/ bin   - search ELF 32 binaries
#   ./firmdiff.sh ./ver1.0/rootfs/ ./ver2.0/rootfs/ so    - search ELF shared objects 
#   ./firmdiff.sh ./ver1.0/rootfs/ ./ver2.0/rootfs/ sh    - search shell scripts
#
# Caveats:
#   1. This version of the script is only interested in ELF 32 binaries when 
#   used with the 'bin' FILE_EXTENSION
#   2. Take into consideration that any unpacked files  inside a rootfs.img should 
#   have also been unpacked.

if [ $# -ne 3 ]; then
    echo "Usage: ./firmdiff.sh [SRC_DIR] [DST_DIR] [FILE_EXTENSION]"
    echo "FILE_EXTENSION examples: bin | so | sh | lua"
    exit 1
fi

src_dir="$1"
dst_dir="$2"
ext="$3"

if [ ! -d "$src_dir" ]; then
    echo "$src_dir is not a valid directory";
    exit 1;
elif [ ! -d "$dst_dir" ]; then
    echo "$dst_dir is not a valid directory";
    exit 1;
fi

tmpfile_src=$(mktemp /tmp/find_src.XXXX)
tmpfile_dst=$(mktemp /tmp/find_dst.XXXX)


check_diff() {
    #check md5 hash differences
    if [ "$ext" = "bin" ]; then
        # special case for binary files
        find "$src_dir" -type f -exec file {} \; 2>/dev/null | grep "ELF 32-bit LSB executable" |\
            cut -d: -f1 | xargs -I {} md5sum {} 2>/dev/null >> "$tmpfile_src"
        find "$dst_dir" -type f -exec file {} \; 2>/dev/null | grep "ELF 32-bit LSB executable" |\
            cut -d: -f1 | xargs -I {} md5sum {} 2>/dev/null >> "$tmpfile_dst"
    else
        find "$src_dir" -type f -name "*.$1" 2>/dev/null |\
            xargs -I {} md5sum "{}" 2>/dev/null >> "$tmpfile_src"
        find "$dst_dir" -type f -name "*.$1" 2>/dev/null |\
            xargs -I {} md5sum "{}" 2>/dev/null >> "$tmpfile_dst"
    fi


    temp=$(mktemp /tmp/temp.XXXX)
    src_hash=$(mktemp /tmp/src_hash.XXXX)
    dst_hash=$(mktemp /tmp/dst_hash.XXXX)
    awk -v prefix="$src_dir" '{sub(prefix, "", $2); print $1, $2}' "$tmpfile_src"\
        > "$temp" && mv "$temp" "$src_hash"
    awk -v prefix="$dst_dir" '{sub(prefix, "", $2); print $1, $2}' "$tmpfile_dst"\
        > "$temp" && mv "$temp" "$dst_hash"
    awk 'NR==FNR {hash[$2]=$1; next} $2 in hash && hash[$2] != $1 {print hash[$2], $1, $2}' "$src_hash" "$dst_hash"
    rm "$src_hash" "$dst_hash"

    #check for new files
    src_files=$(mktemp /tmp/src_files.XXXX)
    dst_files=$(mktemp /tmp/dst_files.XXXX)
    
    awk -v prefix="$src_dir" '{sub(prefix, "", $2); print $2}' "$tmpfile_src" > "$src_files"
    awk -v prefix="$dst_dir" '{sub(prefix, "", $2); print $2}' "$tmpfile_dst" > "$dst_files"
    sort -o "$src_files" "$src_files"
    sort -o "$dst_files" "$dst_files"

    comm -13 "$src_files" "$dst_files"  | awk -v prefix="$dst_dir" '{if (system("grep -q " $0)) {print "[UNIQUE] " prefix $0}}'
    comm -23 "$src_files" "$dst_files"  | awk -v prefix="$src_dir" '{if (system("grep -q " $0)) {print "[UNIQUE] " prefix $0}}'
    rm "$src_files" "$dst_files"
}

check_diff "$ext"

if [ -e "$tmpfile_dst" ]; then
    rm "$tmpfile_dst"
fi

if [ -e "$tmpfile_src" ]; then
    rm "$tmpfile_src"
fi

exit 0
