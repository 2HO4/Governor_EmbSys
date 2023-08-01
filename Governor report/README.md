# Team 9 Governor Design
This is Team 9's implementation of the Pipe-All framework to design a performance aware governor which aims to find the optimal design point that satisfies the target FPS and latency, while minimizing the total power consumption. This design point contains the partitioning points of a particular image classification CNN that divide its parts into 3 parts, the order of the GPU, the Big CPU, and the Little CPU processors in the pipeline. 

The governor is written in C++, which requires the script to be built and loaded into the machine.

## Linux device
If the target device is Linux, compile it with g++ :
```
$ g++ -static-libstdc++ Governor.cpp -o Governor
$ chmod +x Governor
```

## Android device
If the target device is Android you need to cross compile it using clang++ in linux and then push the binary into the android device:
```
$ arm-linux-androideabi-clang++ -static-libstdc++ Governor.cpp -o Governor
$ adb push Governor dir_inside_bord/
```
The *Build_CPP.sh* script sets the path, compiles the governor and push it into the android device:
```
$ ./Build_CPP.sh Governor.cpp
```
You need to define Android-NDK path in your machine into the *Android-NDK* variable and also change the path in your android device based on your desire. 


## Running the Governor
This governor takes four input arguments: target CNN (*Graph*), the number of total partitioning parts in this graph (*TotalParts*),
target FPS (*TargetFPS*), and target latency (*TargetLatency*) in the main function.
```
$ ./Governor Graph #TotalParts #TargetFPS #TargetLatency
```
