qt_internal_add_manual_test(test_spawn
    GUI
    SOURCES
        main.cpp
    PUBLIC_LIBRARIES
        Qt::Gui
        Qt::Quick
        Qt::Quick3D
        Qt::Quick3DPhysics
)

# Resources:
set(qml_resource_files
  "main.qml"
  "box.qml"
  "sphere.qml"
)

qt6_add_resources(test_spawn "qml"
    PREFIX
        "/"
    FILES
        ${qml_resource_files}
)
