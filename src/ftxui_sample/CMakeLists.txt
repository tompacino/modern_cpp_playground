add_executable(intro main.cpp)

target_link_libraries(
  intro
  PRIVATE modern_cpp_playground::modern_cpp_playground_options
          modern_cpp_playground::modern_cpp_playground_warnings)

target_link_system_libraries(
  intro
  PRIVATE
          CLI11::CLI11
          fmt::fmt
          spdlog::spdlog
          lefticus::tools
          ftxui::screen
          ftxui::dom
          ftxui::component)

target_include_directories(intro PRIVATE "${CMAKE_BINARY_DIR}/configured_files/include")
