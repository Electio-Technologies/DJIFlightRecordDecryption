set -e

cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_RUNTIME_OUTPUT_DIRECTORY=.. ../dji-flightrecord-kit/source/FRSample
make -j$(nproc)