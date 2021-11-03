#!/bin/bash
mkdir tmp
mv DRAIT.tar.Z tmp
cd tmp
tar -xf DRAIT.tar.Z
rm -rf ~/ctm/pid/*
source ~/.bash_profile
cd ..
./tmp/setup.sh -silent silent.xml
rm -rf tmp