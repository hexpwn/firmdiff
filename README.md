# What is it
Stupidly naive search for changes in the files of a firmware filesystem.

# Usage

```bash
  ./firmdiff.sh <SRC_DIR> <DST_DIR> <FILE_EXTENSION>
``` 
   `SRC_DIR` and `DST_DIR` should be the, already mounted, directories of the rootfs
   for each firmware version.

   `FILE_EXTENSION` should be a filetype (ex: .so, .lua, .sh. Omit the period)


## Examples
```bash
  ./firmdiff.sh ./ver1.0/rootfs/ ./ver2.0/rootfs/ bin #search ELF 32 binaries
  ./firmdiff.sh ./ver1.0/rootfs/ ./ver2.0/rootfs/ so  #search ELF shared objects
  ./firmdiff.sh ./ver1.0/rootfs/ ./ver2.0/rootfs/ sh  #search shell scripts
``` 

# Caveats
  1. This version of the script is only interested in ELF 32 binaries when
  used with the 'bin' `FILE_EXTENSION`
  2. Take into consideration that any unpacked files inside a rootfs.img should
  have also been unpacked.

# Current version: 1
