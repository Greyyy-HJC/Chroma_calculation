project(iog_to_txt)
cmake_minimum_required(VERSION 3.15)

set(CMAKE_CXX_STANDARD 11)
file(GLOB SOURCE "src/*.cpp")
add_executable(iog_to_txt ${SOURCE})
target_include_directories(iog_to_txt PUBLIC "inc")
