#.rst:
# Find Magnum integration library
# -------------------------------
#
# Finds the Magnum integration library. Basic usage::
#
#  find_package(MagnumIntegration REQUIRED)
#
# This command tries to find Magnum integration library and then defines the
# following:
#
#  MagnumIntegration_FOUND      - Whether the library was found
#
# This command alone is useless without specifying the components:
#
#  Bullet                       - Bullet Physics integration library
#  Ovr                          - Oculus SDK integration library
#
# Example usage with specifying additional components is:
#
#  find_package(MagnumIntegration REQUIRED Bullet)
#
# For each component is then defined:
#
#  MagnumIntegration_*_FOUND    - Whether the component was found
#  MagnumIntegration::*         - Component imported target
#
# The package is found if either debug or release version of each requested
# library is found. If both debug and release libraries are found, proper
# version is chosen based on actual build configuration of the project (i.e.
# Debug build is linked to debug libraries, Release build to release
# libraries).
#
# Additionally these variables are defined for internal usage:
#
#  MAGNUMINTEGRATION_INCLUDE_DIR - Magnum integration include dir (w/o
#   dependencies)
#  MAGNUMINTEGRATION_*_LIBRARY_DEBUG - Debug version of given library, if found
#  MAGNUMINTEGRATION_*_LIBRARY_RELEASE - Release version of given library, if
#   found
#
# Workflows without imported targets are deprecated and the following variables
# are included just for backwards compatibility and only if
# :variable:`MAGNUM_BUILD_DEPRECATED` is enabled:
#
#  MAGNUM_*INTEGRATION_LIBRARIES - Expands to ``MagnumIntegration::*` target.
#   Use ``MagnumIntegration::*` target directly instead.
#
#

#
#   This file is part of Magnum.
#
#   Copyright © 2010, 2011, 2012, 2013, 2014, 2015, 2016
#             Vladimír Vondruš <mosra@centrum.cz>
#
#   Permission is hereby granted, free of charge, to any person obtaining a
#   copy of this software and associated documentation files (the "Software"),
#   to deal in the Software without restriction, including without limitation
#   the rights to use, copy, modify, merge, publish, distribute, sublicense,
#   and/or sell copies of the Software, and to permit persons to whom the
#   Software is furnished to do so, subject to the following conditions:
#
#   The above copyright notice and this permission notice shall be included
#   in all copies or substantial portions of the Software.
#
#   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
#   THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
#   FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
#   DEALINGS IN THE SOFTWARE.
#

# Magnum library dependencies
set(_MAGNUMINTEGRATION_DEPENDENCIES )
foreach(_component ${MagnumIntegration_FIND_COMPONENTS})
    string(TOUPPER ${_component} _COMPONENT)

    if(_component STREQUAL Bullet)
        set(_MAGNUMINTEGRATION_${_COMPONENT}_MAGNUM_DEPENDENCIES SceneGraph Shapes)
    endif()

    list(APPEND _MAGNUMINTEGRATION_DEPENDENCIES ${_MAGNUMINTEGRATION_${_COMPONENT}_MAGNUM_DEPENDENCIES})
endforeach()
find_package(Magnum REQUIRED ${_MAGNUMINTEGRATION_DEPENDENCIES})

# Global integration include dir
find_path(MAGNUMINTEGRATION_INCLUDE_DIR Magnum
    HINTS ${MAGNUM_INCLUDE_DIR})
mark_as_advanced(MAGNUMINTEGRATION_INCLUDE_DIR)

# Ensure that all inter-component dependencies are specified as well
set(_MAGNUMINTEGRATION_ADDITIONAL_COMPONENTS )
foreach(_component ${MagnumIntegration_FIND_COMPONENTS})
    string(TOUPPER ${_component} _COMPONENT)

    # (no inter-component dependencies yet)

    # Mark the dependencies as required if the component is also required
    if(MagnumIntegration_FIND_REQUIRED_${_component})
        foreach(_dependency ${_MAGNUMINTEGRATION_${_COMPONENT}_DEPENDENCIES})
            set(MagnumIntegration_FIND_REQUIRED_${_dependency} TRUE)
        endforeach()
    endif()

    list(APPEND _MAGNUMINTEGRATION_ADDITIONAL_COMPONENTS ${_MAGNUMINTEGRATION_${_COMPONENT}_DEPENDENCIES})
endforeach()

# Join the lists, remove duplicate components
if(_MAGNUMINTEGRATION_ADDITIONAL_COMPONENTS)
    list(INSERT MagnumIntegration_FIND_COMPONENTS 0 ${_MAGNUMINTEGRATION_ADDITIONAL_COMPONENTS})
endif()
if(MagnumIntegration_FIND_COMPONENTS)
    list(REMOVE_DUPLICATES MagnumIntegration_FIND_COMPONENTS)
endif()

# Component distinction (listing them explicitly to avoid mistakes with finding
# components from other repositories)
set(_MAGNUMINTEGRATION_LIBRARY_COMPONENTS "^(Bullet|Ovr)$")

# Additional components
foreach(_component ${MagnumIntegration_FIND_COMPONENTS})
    string(TOUPPER ${_component} _COMPONENT)

    # Create imported target in case the library is found. If the project is
    # added as subproject to CMake, the target already exists and all the
    # required setup is already done from the build tree.
    if(TARGET MagnumIntegration::${_component})
        set(MagnumIntegration_${_component}_FOUND TRUE)
    else()
        # Library components
        if(_component MATCHES ${_MAGNUMINTEGRATION_LIBRARY_COMPONENTS})
            add_library(MagnumIntegration::${_component} UNKNOWN IMPORTED)

            # Try to find both debug and release version
            find_library(MAGNUMINTEGRATION_${_COMPONENT}_LIBRARY_DEBUG Magnum${_component}Integration-d)
            find_library(MAGNUMINTEGRATION_${_COMPONENT}_LIBRARY_RELEASE Magnum${_component}Integration)
            mark_as_advanced(MAGNUMINTEGRATION_${_COMPONENT}_LIBRARY_DEBUG
                MAGNUMINTEGRATION_${_COMPONENT}_LIBRARY_RELEASE)

            if(MAGNUMINTEGRATION_${_COMPONENT}_LIBRARY_RELEASE)
                set_property(TARGET MagnumIntegration::${_component} APPEND PROPERTY
                    IMPORTED_CONFIGURATIONS RELEASE)
                set_property(TARGET MagnumIntegration::${_component} PROPERTY
                    IMPORTED_LOCATION_RELEASE ${MAGNUMINTEGRATION_${_COMPONENT}_LIBRARY_RELEASE})
            endif()

            if(MAGNUMINTEGRATION_${_COMPONENT}_LIBRARY_DEBUG)
                set_property(TARGET MagnumIntegration::${_component} APPEND PROPERTY
                    IMPORTED_CONFIGURATIONS DEBUG)
                set_property(TARGET MagnumIntegration::${_component} PROPERTY
                    IMPORTED_LOCATION_DEBUG ${MAGNUMINTEGRATION_${_COMPONENT}_LIBRARY_DEBUG})
            endif()
        endif()

        # Bullet integration library
        if(_component STREQUAL Bullet)
            find_package(Bullet)
            set_property(TARGET MagnumIntegration::${_component} APPEND PROPERTY
                INTERFACE_INCLUDE_DIRECTORIES ${BULLET_INCLUDE_DIRS})
            # Need to handle special cases where both debug and release
            # libraries are available (in form of debug;A;optimized;B in
            # BULLET_LIBRARIES), thus appending them one by one
            foreach(lib BULLET_DYNAMICS_LIBRARY BULLET_COLLISION_LIBRARY BULLET_MATH_LIBRARY BULLET_SOFTBODY_LIBRARY)
                if(${lib}_DEBUG)
                    set_property(TARGET MagnumIntegration::${_component} APPEND PROPERTY
                        INTERFACE_LINK_LIBRARIES "$<$<NOT:$<CONFIG:Debug>>:${${lib}}>;$<$<CONFIG:Debug>:${${lib}_DEBUG}>")
                else()
                    set_property(TARGET MagnumIntegration::${_component} APPEND PROPERTY
                        INTERFACE_LINK_LIBRARIES ${${lib}})
                endif()
            endforeach()

            set(_MAGNUMINTEGRATION_${_COMPONENT}_INCLUDE_PATH_NAMES MotionState.h)

        # Oculus SDK integration library
        elseif(_component STREQUAL Ovr)
            find_package(OVR)
            set_property(TARGET MagnumIntegration::${_component} APPEND PROPERTY
                INTERFACE_INCLUDE_DIRECTORIES ${OVR_INCLUDE_DIR})
            set_property(TARGET MagnumIntegration::${_component} APPEND PROPERTY
                INTERFACE_LINK_LIBRARIES ${OVR_LIBRARY})

            set(_MAGNUMINTEGRATION_${_COMPONENT}_INCLUDE_PATH_NAMES OvrIntegration.h)
        endif()

        # Find library includes
        if(_component MATCHES ${_MAGNUMINTEGRATION_LIBRARY_COMPONENTS})
            find_path(_MAGNUMINTEGRATION_${_COMPONENT}_INCLUDE_DIR
                NAMES ${_MAGNUMINTEGRATION_${_COMPONENT}_INCLUDE_PATH_NAMES}
                HINTS ${MAGNUMINTEGRATION_INCLUDE_DIR}/Magnum/${_component}Integration)
        endif()

        if(_component MATCHES ${_MAGNUMINTEGRATION_LIBRARY_COMPONENTS})
            # Link to core Magnum library, add other Magnum dependencies
            set_property(TARGET MagnumIntegration::${_component} APPEND PROPERTY
                INTERFACE_LINK_LIBRARIES Magnum::Magnum)
            foreach(_dependency ${_MAGNUMINTEGRATION_${_COMPONENT}_MAGNUM_DEPENDENCIES})
                set_property(TARGET MagnumIntegration::${_component} APPEND PROPERTY
                    INTERFACE_LINK_LIBRARIES Magnum::${_dependency})
            endforeach()

            # Add inter-project dependencies
            foreach(_dependency ${_MAGNUMINTEGRATION_${_COMPONENT}_DEPENDENCIES})
                set_property(TARGET MagnumIntegration::${_component} APPEND PROPERTY
                    INTERFACE_LINK_LIBRARIES MagnumIntegration::${_dependency})
            endforeach()
        endif()

        # Decide if the library was found
        if(_component MATCHES ${_MAGNUMINTEGRATION_LIBRARY_COMPONENTS} AND _MAGNUMINTEGRATION_${_COMPONENT}_INCLUDE_DIR AND (MAGNUMINTEGRATION_${_COMPONENT}_LIBRARY_DEBUG OR MAGNUMINTEGRATION_${_COMPONENT}_LIBRARY_RELEASE))
            set(MagnumIntegration_${_component}_FOUND TRUE)
        else()
            set(MagnumIntegration_${_component}_FOUND FALSE)
        endif()
    endif()

    # Deprecated variables
    if(MAGNUM_BUILD_DEPRECATED AND _component MATCHES ${_MAGNUMINTEGRATION_LIBRARY_COMPONENTS})
        set(MAGNUM_${_COMPONENT}INTEGRATION_LIBRARIES MagnumIntegration::${_component})
    endif()
endforeach()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(MagnumIntegration
    REQUIRED_VARS MAGNUMINTEGRATION_INCLUDE_DIR
    HANDLE_COMPONENTS)
