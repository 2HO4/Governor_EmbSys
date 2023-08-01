#!/bin/bash

adb connect $1
adb root
adb connect $1
adb shell
