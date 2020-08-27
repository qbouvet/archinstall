#!/bin/bash

    # Dependancies installation
echo "installing prerequisites"; read
aurman -S ncurses5-compat-libs
sudo pacman -S  freeglut lib32-freeglut

    # Cuda installation
echo "installing cuda"; read
sudo pacman -S opencl-nvidia cuda cudnn

    # Tensorflwo installation
echo "python-tensorflow-gpu"; read
sudo pacman -S python-tensorflow-cuda tensorboard

    # Testing Installation
printf " Run the following program to test your installation : 

import tensorflow as tf
hello = tf.constant('Hello, TensorFlow!')
sess = tf.Session()
print(sess.run(hello))

"
python

    # Important additional packages
echo "Installing (recommended) additional python modules"; read
pacman -S pip python-h5py python-matplotlib python-numpy python-pillow python-pickleshare

