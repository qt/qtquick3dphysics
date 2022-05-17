cmake_minimum_required(VERSION 3.16)

include(.cmake.conf)
project(QtQuick3DPhysics
    VERSION "${QT_REPO_MODULE_VERSION}"
    DESCRIPTION "Qt Quick3D Physics Extensions"
    HOMEPAGE_URL "https://qt.io/"
    LANGUAGES CXX C
)

# special case begin

# Make sure we only use latest private CMake API, aka no compatibility wrappers.
set(QT_NO_INTERNAL_COMPATIBILITY_FUNCTIONS TRUE)

find_package(Qt6 ${PROJECT_VERSION} CONFIG REQUIRED COMPONENTS BuildInternals Core Gui Qml Quick ShaderTools Quick3D)
find_package(Qt6 ${PROJECT_VERSION} CONFIG OPTIONAL_COMPONENTS Network)
if(QT_BUILD_TESTS OR QT_BUILD_STANDALONE_TESTS)
    find_package(Qt6 ${PROJECT_VERSION} CONFIG REQUIRED COMPONENTS QuickTest)
endif()

# TODO: Fix warnings and remove this
set(QT_REPO_NOT_WARNINGS_CLEAN TRUE)
# special case end

if(INTEGRITY OR QNX OR VXWORKS OR WATCHOS)
    message(NOTICE "Skipping the build as the condition \"NOT INTEGRITY AND NOT QNX AND NOT VXWORKS AND NOT WATCHOS\" is not met.")
    return()
endif()
if(NOT TARGET Qt::Quick)
    message(NOTICE "Skipping the build as the condition \"TARGET Qt::Quick\" is not met.")
    return()
endif()
if(NOT TARGET Qt::Quick3D)
    message(NOTICE "Skipping the build as the condition \"TARGET Qt::Quick3D\" is not met.")
    return()
endif()

# Force generation of static libraries
set(PX_GENERATE_STATIC_LIBRARIES ON CACHE BOOL "Generate static libraries" FORCE)

# For windows debug
set(NV_USE_DEBUG_WINCRT On CACHE BOOL  "Use the debug version of the CRT" FORCE)

qt_build_repo()
