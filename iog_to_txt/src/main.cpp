#include <iostream>
// #include <fstream>
// #include <string>
// #include <cstdlib>
// #include <sstream>
// #include <cstring>
#include "io_general_class.h"
#include "io_general.h"

int main(int argc, const char* argv[]) {
  if (argc != 2) {
    //std::cerr << R"(Usage: iog_to_txt "input.iog"\n)";
    std::cerr << "Usage: iog_to_txt \"input.iog\"\n";
    exit(EXIT_FAILURE);
  }

  general_data_base iog { argv[1] };
  iog.load();
  iog.print_all();

  return 0;
}
