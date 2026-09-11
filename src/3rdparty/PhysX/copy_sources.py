#!/usr/bin/python
import os
import sys
import shutil
from pathlib import Path

# Directories, relative to the PhysX SDK root, that we copy sources from.
source_dirs = ['include', 'source']

# Files that must not be copied, relative to the PhysX SDK root. The PhysX
# build system writes PxConfig.h, and we do not use that build system.
excluded_files = ['include/PxConfig.h',
                  'source/compiler/resource_x64/resource.h',
                  'source/compiler/resource_x86/resource.h']

# Directories that must not be copied, relative to the PhysX SDK root.
#
# PhysX is built with DISABLE_CUDA_PHYSX, so everything below the GPU
# implementation, its loader and the CUDA context manager is compiled out. The
# public headers under include/cudamanager and include/gpu are kept, since the
# other public headers include them unconditionally.
#
# OmniPVD is built with PX_SUPPORT_OMNI_PVD=0, like the upstream release
# configuration does, so its sampler and the PVD runtime headers it needs are
# not used either. The same goes for the old PVD, which is compiled out of the
# core by PX_SUPPORT_PVD being left undefined.
#
# Serialization, and the metadata tables that only serialization and PVD use,
# are not part of the copy either: Qt Quick 3D Physics cooks and loads meshes
# through the cooking API and never touches PxSerialization or RepX.
excluded_dirs = ['source/compiler',
                 'source/cudamanager',
                 'source/gpuarticulation',
                 'source/gpubroadphase',
                 'source/gpucommon',
                 'source/gpunarrowphase',
                 'source/gpusimulationcontroller',
                 'source/gpusolver',
                 'source/physx/src/gpu',
                 'source/physxgpu',
                 'source/physx/src/omnipvd',
                 'source/physxextensions/src/omnipvd',
                 'source/physxextensions/src/serialization',
                 'source/physxmetadata',
                 'source/pvd']


# Files that are copied even though their directory is excluded.
#
# The OmniPVD*SetData.h headers are included unconditionally by the core and
# the extensions, and provide the empty macro definitions used when OmniPVD is
# disabled.
#
# The three headers below are the only things the parts of PhysX we do build
# still need from the excluded PVD and serialization directories: an interface
# NpPhysics.h includes but only uses behind PX_SUPPORT_PVD, an allocator
# wrapper the string table is written in terms of, and a fopen() wrapper the
# default streams use. All three only depend on the foundation.
included_files = ['source/physx/src/omnipvd/NpOmniPvdSetData.h',
                  'source/physxextensions/src/omnipvd/ExtOmniPvdSetData.h',
                  'source/physxextensions/src/serialization/File/SnFile.h',
                  'source/pvd/include/PsPvd.h',
                  'source/pvd/include/PxProfileAllocatorWrapper.h']


def excluded(path: str) -> bool:
    if path in included_files:
        return False
    # Vehicles are unused, and skipping them keeps the command line short
    # enough on Windows.
    if 'vehicle' in path.lower():
        return True
    if path in excluded_files:
        return True
    return any(path.startswith(d + '/') for d in excluded_dirs)


def copy(src: str, dst: str) -> None:
    src_path = os.path.abspath(os.path.normpath(src))
    dst_path = os.path.abspath(os.path.normpath(dst))
    assert not os.path.isfile(src_path), f"Directory is a file: {src}"
    assert not os.path.isfile(dst_path), f"Directory is a file: {dst}"

    print(f"Copying from {src_path} to {dst_path}")

    files = []

    for source_dir in source_dirs:
        for pattern in ['*.cpp', '*.h']:
            for path in Path(src_path, source_dir).rglob(pattern):
                relative = path.relative_to(src_path).as_posix()
                if not excluded(relative):
                    files.append(relative)

    for relative in sorted(files):
        dest_fpath = os.path.join(dst_path, relative)
        os.makedirs(os.path.dirname(dest_fpath), exist_ok=True)
        shutil.copy(os.path.join(src_path, relative), dest_fpath)
        print(relative)


if __name__ == '__main__':
    if len(sys.argv) != 3:
        print("Usage: copy_sources.py /.../physx-root/physx /.../qtquick3dphysics/src/3rdparty/PhysX")
        sys.exit(1)
    copy(sys.argv[1], sys.argv[2])
