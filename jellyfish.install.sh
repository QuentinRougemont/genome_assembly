#Jellyfish install: 
wget https://github.com/gmarcais/Jellyfish/releases/download/v2.3.1/jellyfish-2.3.1.tar.gz
tar zxvf jellyfish-2.3.1.tar.gz 
cd jellyfish-2.3.1
./configure --prefix=$(pwd)
make -j8 
make install

