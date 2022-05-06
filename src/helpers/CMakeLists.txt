#####################################################################
## qtquick3dhelpersplugin Plugin:
#####################################################################

qt_internal_add_qml_module(Quick3DPhysicsHelpers
    URI "QtQuick3D.Physics.Helpers"
    VERSION "${PROJECT_VERSION}"
    CLASSNAME QtQuick3DPhysicsHelpersPlugin
    PLUGIN_TARGET qtquick3dphysicshelpersplugin
    SOURCES
        qcapsulegeometry.cpp qcapsulegeometry_p.h
    DEPENDENCIES
        QtQuick3DPhysics/auto
    PAST_MAJOR_VERSIONS 1
    DEFINES
        QT_BUILD_QUICK3DPHYSICSHELPERS_LIB
    LIBRARIES
        Qt::Quick3DPhysics
    PUBLIC_LIBRARIES
        Qt::Qml
        Qt::Quick
        Qt::Quick3D
)

