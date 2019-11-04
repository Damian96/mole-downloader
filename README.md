# Mole Downloader

A shell script to download zipped files of courses on [mole](https://mole.citycollege.sheffield.eu/)'s platform

# Usage

To use just run it with bash like:

```
bash mole-downloader.sh
```

Make sure to remove your temporary files when you are completely done with the tool.

There are two other tools to ease the management of your downloaded files as well.

- flush.sh
- munzip.sh (depends on 7z, mostly met as p7zip on repositories)

Flush erases all the contents of the directory except the scripts themselves(useful for when you want a full clean of your folder to redownload the material).

Munzip uses 7z to uncompress all the downloaded archives quickly, in folders that are named after the archive name.

To use them, run them the same way you did with mole-downloader.sh

```
bash flush.sh
```

```
bash munzip.sh
```

# Contributors

Created by [Damian96](https://github.com/Damian96)

Contributor: [pgram1](https://github.com/pgram1)

# License

Licensed under the [MIT license](LICENSE)
