include(cmake/SystemLink.cmake)
include(cmake/LibFuzzer.cmake)
include(CMakeDependentOption)
include(CheckCXXCompilerFlag)


macro(modern_cpp_playground_supports_sanitizers)
  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND NOT WIN32)
    set(SUPPORTS_UBSAN ON)
  else()
    set(SUPPORTS_UBSAN OFF)
  endif()

  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND WIN32)
    set(SUPPORTS_ASAN OFF)
  else()
    set(SUPPORTS_ASAN ON)
  endif()
endmacro()

macro(modern_cpp_playground_setup_options)
  option(modern_cpp_playground_ENABLE_HARDENING "Enable hardening" ON)
  option(modern_cpp_playground_ENABLE_COVERAGE "Enable coverage reporting" OFF)
  cmake_dependent_option(
    modern_cpp_playground_ENABLE_GLOBAL_HARDENING
    "Attempt to push hardening options to built dependencies"
    ON
    modern_cpp_playground_ENABLE_HARDENING
    OFF)

  modern_cpp_playground_supports_sanitizers()

  if(NOT PROJECT_IS_TOP_LEVEL OR modern_cpp_playground_PACKAGING_MAINTAINER_MODE)
    option(modern_cpp_playground_ENABLE_IPO "Enable IPO/LTO" OFF)
    option(modern_cpp_playground_WARNINGS_AS_ERRORS "Treat Warnings As Errors" OFF)
    option(modern_cpp_playground_ENABLE_USER_LINKER "Enable user-selected linker" OFF)
    option(modern_cpp_playground_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" OFF)
    option(modern_cpp_playground_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(modern_cpp_playground_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" OFF)
    option(modern_cpp_playground_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(modern_cpp_playground_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(modern_cpp_playground_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(modern_cpp_playground_ENABLE_CLANG_TIDY "Enable clang-tidy" OFF)
    option(modern_cpp_playground_ENABLE_CPPCHECK "Enable cpp-check analysis" OFF)
    option(modern_cpp_playground_ENABLE_PCH "Enable precompiled headers" OFF)
    option(modern_cpp_playground_ENABLE_CACHE "Enable ccache" OFF)
  else()
    option(modern_cpp_playground_ENABLE_IPO "Enable IPO/LTO" ON)
    option(modern_cpp_playground_WARNINGS_AS_ERRORS "Treat Warnings As Errors" ON)
    option(modern_cpp_playground_ENABLE_USER_LINKER "Enable user-selected linker" OFF)
    option(modern_cpp_playground_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" ${SUPPORTS_ASAN})
    option(modern_cpp_playground_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(modern_cpp_playground_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" ${SUPPORTS_UBSAN})
    option(modern_cpp_playground_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(modern_cpp_playground_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(modern_cpp_playground_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(modern_cpp_playground_ENABLE_CLANG_TIDY "Enable clang-tidy" ON)
    option(modern_cpp_playground_ENABLE_CPPCHECK "Enable cpp-check analysis" ON)
    option(modern_cpp_playground_ENABLE_PCH "Enable precompiled headers" OFF)
    option(modern_cpp_playground_ENABLE_CACHE "Enable ccache" ON)
  endif()

  if(NOT PROJECT_IS_TOP_LEVEL)
    mark_as_advanced(
      modern_cpp_playground_ENABLE_IPO
      modern_cpp_playground_WARNINGS_AS_ERRORS
      modern_cpp_playground_ENABLE_USER_LINKER
      modern_cpp_playground_ENABLE_SANITIZER_ADDRESS
      modern_cpp_playground_ENABLE_SANITIZER_LEAK
      modern_cpp_playground_ENABLE_SANITIZER_UNDEFINED
      modern_cpp_playground_ENABLE_SANITIZER_THREAD
      modern_cpp_playground_ENABLE_SANITIZER_MEMORY
      modern_cpp_playground_ENABLE_UNITY_BUILD
      modern_cpp_playground_ENABLE_CLANG_TIDY
      modern_cpp_playground_ENABLE_CPPCHECK
      modern_cpp_playground_ENABLE_COVERAGE
      modern_cpp_playground_ENABLE_PCH
      modern_cpp_playground_ENABLE_CACHE)
  endif()

  modern_cpp_playground_check_libfuzzer_support(LIBFUZZER_SUPPORTED)
  if(LIBFUZZER_SUPPORTED AND (modern_cpp_playground_ENABLE_SANITIZER_ADDRESS OR modern_cpp_playground_ENABLE_SANITIZER_THREAD OR modern_cpp_playground_ENABLE_SANITIZER_UNDEFINED))
    set(DEFAULT_FUZZER ON)
  else()
    set(DEFAULT_FUZZER OFF)
  endif()

  option(modern_cpp_playground_BUILD_FUZZ_TESTS "Enable fuzz testing executable" ${DEFAULT_FUZZER})

endmacro()

macro(modern_cpp_playground_global_options)
  if(modern_cpp_playground_ENABLE_IPO)
    include(cmake/InterproceduralOptimization.cmake)
    modern_cpp_playground_enable_ipo()
  endif()

  modern_cpp_playground_supports_sanitizers()

  if(modern_cpp_playground_ENABLE_HARDENING AND modern_cpp_playground_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR modern_cpp_playground_ENABLE_SANITIZER_UNDEFINED
       OR modern_cpp_playground_ENABLE_SANITIZER_ADDRESS
       OR modern_cpp_playground_ENABLE_SANITIZER_THREAD
       OR modern_cpp_playground_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    message("${modern_cpp_playground_ENABLE_HARDENING} ${ENABLE_UBSAN_MINIMAL_RUNTIME} ${modern_cpp_playground_ENABLE_SANITIZER_UNDEFINED}")
    modern_cpp_playground_enable_hardening(modern_cpp_playground_options ON ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()
endmacro()

macro(modern_cpp_playground_local_options)
  if(PROJECT_IS_TOP_LEVEL)
    include(cmake/StandardProjectSettings.cmake)
  endif()

  add_library(modern_cpp_playground_warnings INTERFACE)
  add_library(modern_cpp_playground_options INTERFACE)

  include(cmake/CompilerWarnings.cmake)
  modern_cpp_playground_set_project_warnings(
    modern_cpp_playground_warnings
    ${modern_cpp_playground_WARNINGS_AS_ERRORS}
    ""
    ""
    ""
    "")

  if(modern_cpp_playground_ENABLE_USER_LINKER)
    include(cmake/Linker.cmake)
    configure_linker(modern_cpp_playground_options)
  endif()

  include(cmake/Sanitizers.cmake)
  modern_cpp_playground_enable_sanitizers(
    modern_cpp_playground_options
    ${modern_cpp_playground_ENABLE_SANITIZER_ADDRESS}
    ${modern_cpp_playground_ENABLE_SANITIZER_LEAK}
    ${modern_cpp_playground_ENABLE_SANITIZER_UNDEFINED}
    ${modern_cpp_playground_ENABLE_SANITIZER_THREAD}
    ${modern_cpp_playground_ENABLE_SANITIZER_MEMORY})

  set_target_properties(modern_cpp_playground_options PROPERTIES UNITY_BUILD ${modern_cpp_playground_ENABLE_UNITY_BUILD})

  if(modern_cpp_playground_ENABLE_PCH)
    target_precompile_headers(
      modern_cpp_playground_options
      INTERFACE
      <vector>
      <string>
      <utility>)
  endif()

  if(modern_cpp_playground_ENABLE_CACHE)
    include(cmake/Cache.cmake)
    modern_cpp_playground_enable_cache()
  endif()

  include(cmake/StaticAnalyzers.cmake)
  if(modern_cpp_playground_ENABLE_CLANG_TIDY)
    modern_cpp_playground_enable_clang_tidy(modern_cpp_playground_options ${modern_cpp_playground_WARNINGS_AS_ERRORS})
  endif()

  if(modern_cpp_playground_ENABLE_CPPCHECK)
    modern_cpp_playground_enable_cppcheck(${modern_cpp_playground_WARNINGS_AS_ERRORS} "" # override cppcheck options
    )
  endif()

  if(modern_cpp_playground_ENABLE_COVERAGE)
    include(cmake/Tests.cmake)
    modern_cpp_playground_enable_coverage(modern_cpp_playground_options)
  endif()

  if(modern_cpp_playground_WARNINGS_AS_ERRORS)
    check_cxx_compiler_flag("-Wl,--fatal-warnings" LINKER_FATAL_WARNINGS)
    if(LINKER_FATAL_WARNINGS)
      # This is not working consistently, so disabling for now
      # target_link_options(modern_cpp_playground_options INTERFACE -Wl,--fatal-warnings)
    endif()
  endif()

  if(modern_cpp_playground_ENABLE_HARDENING AND NOT modern_cpp_playground_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR modern_cpp_playground_ENABLE_SANITIZER_UNDEFINED
       OR modern_cpp_playground_ENABLE_SANITIZER_ADDRESS
       OR modern_cpp_playground_ENABLE_SANITIZER_THREAD
       OR modern_cpp_playground_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    modern_cpp_playground_enable_hardening(modern_cpp_playground_options OFF ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()

endmacro()
