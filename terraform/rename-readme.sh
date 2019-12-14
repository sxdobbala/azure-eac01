#for each directory in modules with a main.tf
for RM in `find modules -iname README.md -print0 | xargs -0 -n1 dirname`
do
  mv $RM/README.md $RM/INTRO.md
done
