#!/usr/bin/env bash
<<COMMENT1
  Requires the use of terraform-docs: https://github.com/segmentio/terraform-docs
  Install using homebrew, e.g.
  brew install terraform-docs

  Script is executed without arguments. It will auto-generate a README.md
  for each terraform module by concatenating INTRO.md with auto-generated
  markdown tables for input and output variables and putting into README.md
COMMENT1

#for each directory in modules with a main.tf
for MDir in `find modules -iname main.tf -print0 | xargs -0 -n1 dirname`
do
  terraform-docs markdown table $MDir > $MDir/TEMP.md
  if [ -f "$MDir/INTRO.md" ]; then
    echo "Found INTRO.md in $MDir"
    cat $MDir/INTRO.md $MDir/TEMP.md > $MDir/README.md
    rm $MDir/TEMP.md
  else
    echo "Did not find INTRO.md in $MDir... renaming"
    mv $MDir/TEMP.md $MDir/README.md
  fi
done
