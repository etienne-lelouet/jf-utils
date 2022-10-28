# LIST OF UTILS

## create_symlinks.sh

Create symlinks to all the files contained at the first level of the directory passed as the first positional argument into the directory passed as the second positional argument (creating it if it does not exist) or the current working directory.

- Using the `--filterexpr` option, you can filter out certain files from the source directory. As this filter is passed directly to `find ` using the regextype `posix-extended`, your filter must respect [the following syntax)(https://www.gnu.org/software/findutils/manual/html_node/find_html/posix_002dextended-regular-expression-syntax.html).

- Using the `--sedexpr` option, you can pass a sed commmand that will transform the original file's base name into another. Your system's `sed` is called with the -E option, so your command must be compatible. The link and the original file have the same base name if this argument is not set.

- `--dry-run-only` will make `create_symlink.sh` display what it would do and then stop. If you don't specify it, it will ask for confirmation wether or not you want to apply said changes.

- `--no-dry-run` will immediatly apply the changes, without asking for confirmation.

- If both `--no-dry-run` and `--dry-run-only` are used, nothing happens.

- If the link you are trying to create already exists, you will be asked for confirmation wether you want do overwrite it or not (you will also be given the option to overwrite for all following occurences). If you want to overwrite unconditionally, used the `--overwrite-all` flag.

- `--exit-on-symlink-error` will exit the program if one of the symlink creation failed.

