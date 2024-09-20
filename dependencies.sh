#!/bin/bash - 
#===============================================================================
#
#          FILE: dependencies.sh
# 
#         USAGE: ./dependencies.sh
# 
#   DESCRIPTION: install a bunch of dependencies not installable through conda 
# 
#       OPTIONS: ---
#        AUTHOR: Q. ROUGEMONT 
#  ORGANIZATION: CNRS 
#       CREATED: 29/08/2024 10:18:12
#===============================================================================

# - Jellyfish install : 
command='jellyfish'
if ! command -v $command &> /dev/null
then
    echo "$command could not be found"
    echo "will try a manual installation" 

    mkdir softs
    cd softs
    wget https://github.com/gmarcais/Jellyfish/releases/download/v2.3.1/jellyfish-2.3.1.tar.gz
    tar zxvf jellyfish-2.3.1.tar.gz 
    cd jellyfish-2.3.1
    ./configure --prefix=$(pwd)
    make -j8 
    if ! make install ; then
        echo "installation of $command failed"
        exit 1
    fi
    
    cd bin/
    path=$(pwd)
    echo -e "\n#Path to $command\nexport PATH=\$PATH:$path" >> ~/.bashrc 
    source ~/.bashrc  
    cd ../../../

fi

#activate env to have pandas 
eval "$(conda shell.bash hook)"
conda activate assembly_env_full

# - compleasm (faster than the slow BUSCO) :
command='compleasm.py'
if ! command -v $command &> /dev/null
then
    echo "$command could not be found"
    echo "will try a manual installation" 
    mkdir softs 2>/dev/null
    cd softs
    wget https://github.com/huangnengCSU/compleasm/releases/download/v0.2.6/compleasm-0.2.6_x64-linux.tar.bz2
    tar -jxvf compleasm-0.2.6_x64-linux.tar.bz2
    cd compleasm_kit
    if ! ./compleasm.py 1>/dev/null ; then
        echo "installation of $command failed"
        exit 1
    fi
    path=$(pwd)
    echo -e "\n#Path to $command\nexport PATH=\$PATH:$path" >> ~/.bashrc 
    echo "sourcing bashrc"
    source ~/.bashrc
    cd ../../

fi


# - dorado for ONT base calling :
command='dorado'
if ! command -v $command &> /dev/null
then
    echo "$command could not be found"
    echo "will try a manual installation" 

    mkdir softs 2>/dev/null
    cd softs 2>/dev/null

#  - Dorado install : 
    wget https://cdn.oxfordnanoportal.com/software/analysis/dorado-0.7.3-linux-x64.tar.gz
    tar zxvf dorado-0.7.3-linux-x64.tar.gz
    cd dorado-0.7.3-linux-x64/bin
    if ! ./dorado 2>/dev/null ; then 
        echo "installation of $command failed"
        exit 1
    fi

    path=$(pwd)
    echo -e "\n#Path to $command\nexport PATH=\$PATH:$path" >> ~/.bashrc 
    source ~/.bashrc  
    cd ../../../

fi


# - CRAQ install :
#install pycircos first (not installed in the env):
pip install python-circos

command='craq'
if ! command -v $command &> /dev/null
then
    echo "$command could not be found"
    echo "will try a manual installation" 

    mkdir softs 2>/dev/null
    cd softs 2>/dev/null


    git clone https://github.com/JiaoLaboratory/CRAQ.git
    cd CRAQ/Example/ && rm -rf Output 
    if ! bash run_example.sh ; then
        echo "installation of $command failed"
        exit 1
    fi
    
    cd ../bin
    chmod +x craq
    path=$(pwd)
    echo -e "\n#Path to $command\nexport PATH=\$PATH:$path" >> ~/.bashrc 
    source ~/.bashrc  
    cd ../../
fi
