# Creating a MSTR cloud instance

For now, I am using the same (null_resource) mechanisms to create.  Don is working on a go project.

Because of this, to tear down an instance requires a two step process

First, set state="stop" in the definition, then apply, it will run the "stopanddestroyenvironment.py" script

Then, remove the module block.

Not ideal, but that's how it works for now.
