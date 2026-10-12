cmake_minimum_required(VERSION 3.25)

set(PROJECT_NAME Vulkan_Lab_Seven)
project(${PROJECT_NAME})

set_property(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} 
    PROPERTY VS_STARTUP_PROJECT ${PROJECT_NAME})

ADD_DEFINITIONS(-DUNICODE)
ADD_DEFINITIONS(-D_UNICODE)

file(GLOB SOURCE_FILES CONFIGURE_DEPENDS ./*.h ./*.cpp)
file(GLOB SHADER_FILES CONFIGURE_DEPENDS ./*.hlsl ./*.glsl)
file(GLOB TINYGLTF_FILES CONFIGURE_DEPENDS ./TinyGLTF/*.h ./TinyGLTF/*.hpp ./TinyGLTF/*.cpp)

if(WIN32)
    # By default CMake selects "ALL_BUILD" as the startup project
    set_property(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} 
        PROPERTY VS_STARTUP_PROJECT ${PROJECT_NAME})
    # This will tell Visual Studio to put the shaders under their own group
    set_property(GLOBAL PROPERTY USE_FOLDERS ON)
    source_group(TREE ${CMAKE_CURRENT_SOURCE_DIR} FILES ${VERTEX_SHADERS})
    source_group(TREE ${CMAKE_CURRENT_SOURCE_DIR} FILES ${PIXEL_SHADERS})
    source_group("TinyGLTF" FILES ${TINYGLTF_FILES})

    # Set runtime library
    set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreadedDLL")
    
    # Add KTX texture loading support
    include_directories(${CMAKE_SOURCE_DIR}/ktx/include)

    # Find the KTX libraries
    find_library(KTX_LIB_D NAMES ktx_x64_d PATHS ${CMAKE_SOURCE_DIR}/ktx/lib)
    find_library(KTX_LIB_R NAMES ktx_x64_r PATHS ${CMAKE_SOURCE_DIR}/ktx/lib)

    # Create the executable
    add_executable (${PROJECT_NAME} ${SOURCE_FILES} ${SHADER_FILES})

    # Explicitly map your Vulkan SDK Directories on E: drive
    target_include_directories(${PROJECT_NAME} PUBLIC "E:/VulkanSDK/1.4.363.0/Include")
    target_link_directories(${PROJECT_NAME} PUBLIC "E:/VulkanSDK/1.4.363.0/Lib")

    # Link Vulkan, Shaderc, and KTX explicitly
    target_link_libraries(${PROJECT_NAME} 
        PUBLIC
        vulkan-1.lib
        shaderc_combined.lib
        debug ${KTX_LIB_D} 
        optimized ${KTX_LIB_R}
    )
endif()

# Linux section
if(UNIX AND NOT APPLE)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -pthread -lX11 -lshaderc_combined")
    find_package(X11)
    find_package(Vulkan REQUIRED)
    link_libraries(${X11_LIBRARIES})
    include_directories(${X11_INCLUDE_DIR})
    include_directories(${Vulkan_INCLUDE_DIR}) 
    link_libraries(${Vulkan_LIBRARIES})
    link_libraries(/usr/lib/x86_64-linux-gnu/libshaderc_combined.a)
    add_executable (${PROJECT_NAME} ${SOURCE_FILES} ${SHADER_FILES})
endif()

# macOS section
if(APPLE)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11 -fmodules -fcxx-modules")
    set(Architecture ${CMAKE_OSX_ARCHITECTURES})
    find_package(Vulkan REQUIRED)
    include_directories(${Vulkan_INCLUDE_DIR}) 
    link_libraries(${Vulkan_LIBRARIES})
    link_libraries(/usr/local/lib/libshaderc_combined.a)
    add_executable (${PROJECT_NAME} main.mm)
endif()

# Exclude shaders from build
set_source_files_properties(${SHADER_FILES} PROPERTIES VS_TOOL_OVERRIDE "none")

# Auto git commit and push
add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
    COMMAND git add --all || ver > nul
    COMMAND git commit -a -m "auto commit" || ver > nul
    COMMAND git push || ver > nul
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    VERBATIM USES_TERMINAL
)

# Explicitly map your Vulkan SDK and TinyGLTF Directories on E: drive
target_include_directories(${PROJECT_NAME} PUBLIC 
	"E:/VulkanSDK/1.4.363.0/Include"
        "${CMAKE_CURRENT_SOURCE_DIR}/TinyGLTF"
)
target_link_directories(${PROJECT_NAME} PUBLIC "E:/VulkanSDK/1.4.363.0/Lib")


