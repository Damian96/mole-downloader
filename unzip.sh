#!/bin/bash
for a in *.zip
do
  b=${a%%.zip}
  7z -y x "$a" -o"$b"
done
rm *.zip
