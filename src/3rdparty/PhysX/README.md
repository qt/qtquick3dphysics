# PhysX

This is the PhysX project used by Qt Quick 3D Physics. It is a copy of the parts of https://github.com/NVIDIA-Omniverse/PhysX that we build, with an added CMake project.
It is using a clean checkout of version 5.9.0 with some minor patches applied and stored as .patch files in the patches directory for reference.

Updating it to a new version means, in this directory:

1. `./copy_sources.py <path to the physx directory of a PhysX checkout> .`, which replaces the sources with that version, leaving out the parts we do not build: the build system, the GPU implementation, the vehicle library, OmniPVD, the old PVD and serialization. Read the top of the script for the details.
2. `git apply patches/*.patch`, which takes them in the order they are numbered.
3. `./find_includes.py`, which updates the source and include directory lists in CMakeLists.txt from the files that copy_sources.py left here.
