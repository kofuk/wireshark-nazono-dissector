project(
    'nazono-dissector',
    'cpp',
    version: '0.0.1',
    default_options: ['warning_level=3', 'cpp_std=c++20'],
)

wireshark_dep = dependency('wireshark')

shared_library('nazono-dissector', 'nazono.cc', dependencies: wireshark_dep)
