module load gcc/9.3.0

rm -rf build/
mkdir build
cd build
cmake ..
cmake --build .
cd ..

cp ./build/iog_to_txt ./iog_to_txt