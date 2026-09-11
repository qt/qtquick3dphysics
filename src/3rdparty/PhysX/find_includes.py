#!/usr/bin/python
#
# Updates the generated parts of CMakeLists.txt from the files that are actually in this
# directory, which is what has to happen after copy_sources.py has imported a new version of
# PhysX. Run it here, with no arguments.
#
# Each of the four lists is replaced as a whole, from the call it belongs to down to the line
# closing that call, so whatever was there before is gone. The BEGIN GENERATED and END
# GENERATED markers it writes around them are there to say so in the file itself; the lists are
# found by the calls, not by the markers, so removing or mangling a marker changes nothing.
# Everything else in CMakeLists.txt is written by hand and left alone.

import os
from pathlib import Path

CMAKELISTS = 'CMakeLists.txt'

SOURCES = 'SOURCES'
WINDOWS_SOURCES = 'WINDOWS SOURCES'
UNIX_SOURCES = 'UNIX SOURCES'
INCLUDE_DIRECTORIES = 'INCLUDE DIRECTORIES'

# The call each list belongs to, and how far its entries are indented.
list_anchors = {
    SOURCES: ('qt_internal_extend_target(BundledPhysX\n    SOURCES\n', 8),
    WINDOWS_SOURCES: ('if(WIN32 OR MSVC)\n    qt_internal_extend_target(BundledPhysX\n'
                      '        SOURCES\n', 12),
    UNIX_SOURCES: ('if(UNIX)\n    qt_internal_extend_target(BundledPhysX\n'
                   '        SOURCES\n', 12),
    INCLUDE_DIRECTORIES: ('qt_internal_extend_target(BundledPhysX\n'
                          '    INCLUDE_DIRECTORIES\n', 8),
}


def is_windows(name):
    return name.lower().find('windows') != -1


def is_unix(name):
    return name.lower().find('unix') != -1 or name.lower().find('linux') != -1


def collect():
    """Sorts the sources and the headers in this directory into the four generated lists."""
    lists = {name: [] for name in list_anchors}

    for path in Path('.').rglob('*.cpp'):
        name = path.as_posix()
        if is_windows(name):
            lists[WINDOWS_SOURCES].append(name)
        elif is_unix(name):
            lists[UNIX_SOURCES].append(name)
        elif name.find('CmMathUtils.cpp') == -1:
            # CmMathUtils.cpp is a leftover from PhysX 4.1.1 that no version since has built.
            # Keep ignoring it, so a version that does contain it does not end up in the build.
            lists[SOURCES].append(name)

    for path in Path('.').rglob('*.h'):
        name = path.as_posix()
        if is_windows(name):
            lists[WINDOWS_SOURCES].append(name)
        elif is_unix(name):
            lists[UNIX_SOURCES].append(name)
        else:
            lists[SOURCES].append(name)
        lists[INCLUDE_DIRECTORIES].append(name.rpartition('/')[0])

    # This directory holds no headers of its own, so the loop above does not pick it up, but it
    # is still included by path from elsewhere.
    lists[INCLUDE_DIRECTORIES].append('source/common/include')

    # Sorted as strings, so the lists come out in the order they read in.
    return {name: sorted(set(paths)) for name, paths in lists.items()}


def fill_list(text, name, paths):
    """Replaces the whole of the list called 'name' with 'paths'."""
    anchor, width = list_anchors[name]
    if anchor not in text:
        raise SystemExit(f"{CMAKELISTS} has no call to put the {name} list in")

    indent = ' ' * width
    start = text.index(anchor) + len(anchor)
    end = text.index(' ' * (width - 4) + ')\n', start)

    lines = ''.join(indent + path + '\n' for path in paths)
    return (text[:start] + f"{indent}# BEGIN GENERATED {name}\n" + lines
            + f"{indent}# END GENERATED {name}\n" + text[end:])


if __name__ == '__main__':
    if not os.path.isfile(CMAKELISTS):
        raise SystemExit(f"Run this in the directory holding {CMAKELISTS}")

    lists = collect()

    text = open(CMAKELISTS).read()
    for name in [SOURCES, WINDOWS_SOURCES, UNIX_SOURCES, INCLUDE_DIRECTORIES]:
        text = fill_list(text, name, lists[name])
    open(CMAKELISTS, 'w').write(text)

    sources = [path for name in [SOURCES, WINDOWS_SOURCES, UNIX_SOURCES]
               for path in lists[name] if path.endswith('.cpp')]
    print(f"{CMAKELISTS}: {len(sources)} sources, "
          f"{len(lists[INCLUDE_DIRECTORIES])} include directories")
