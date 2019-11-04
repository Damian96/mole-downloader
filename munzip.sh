#!/bin/bash
if [ "$1" == "-h" ] || [ "$1" == "--help" ]
then
  echo "Unzip utility for 7z"
  echo "Default behavior: Unzip all zip archives"
  echo "-k or --keep: Keep zip archives"
  echo "-h or --help: Display this message"
  exit
fi
count=`ls -1 *.zip 2>/dev/null | wc -l`
if [ "$count" != 0 ]
then
  for a in *.zip
  do
    b=${a%%.zip}
    7z -y x "$a" -o"$b"
  done
  if [ "$1" == "-k" ] || [ "$1" == "--keep" ]
  then
    echo "I'll keep the zip files"
  else
    rm *.zip
  fi
else
  echo "No zip files in directory"
fi
