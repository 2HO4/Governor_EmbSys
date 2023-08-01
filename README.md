# Embedded System Project

## Table of Contents
1. [Power-Performance Characterisation analysis](#power-performance-characterisation-analysis)
2. [Power-Performance Report](#power-performance-report)
3. [Governor Development](#governor-development)
4. [Governor Optimization](#governor-optimization)
5. [Governor Report](#governor-report)

## Introduction
Embedded systems operate in power-constrained environments, and governors are essential for power management in these systems. This project focuses on developing a new embedded system Governor from scratch, specifically designed for power management in a Machine Learning (ML) application.

## System Requirements
- Laptop running Ubuntu 20.04 with a USB-A port (other OS not supported in this lab)
- USB-A adapter required if the laptop lacks a built-in USB-A port

## About Governors
Governors are Operating System (OS) sub-routines responsible for managing power in embedded systems [3]. They can be either general-purpose or application-specific. We have created an application-specific Governor to perform power management for a Machine Learning (ML) application.

## ML Application
We will focus on power management for a Convolutional Neural Network (CNN) inference, a popular ML application. Five state-of-the-art image classification CNNs will be used: AlexNet, GoogleNet, MobileNet, ResNet50, and SqueezeNet. These CNNs will be executed using the ARM-CL framework on ARM-based Heterogeneous Multi-Processor Systems on Chips (HMPSoCs).

## About HMPSoCs
HMPSoCs are Integrated Circuits (ICs) that integrate different processing cores on a single die. They are widely used in portable embedded devices like smartphones and gaming handhelds. In this project, we will work with the Amlogic A311D HMPSoC in the Khadas Vim 3 embedded platform.

## Project Structure
The project consists of the following components:
1. **Power-Performance Characterisation Analysis:** This section analyzes the power-performance characteristics of the embedded system.
2. **Power-Performance Report:** A report summarizing the findings and insights from the power-performance analysis.
3. **Governor Development:** Where we will write the new embedded system Governor.
4. **Governor Optimization:** This section involves optimizing the Governor's performance and power management capabilities.
5. **Governor Report:** A detailed report showcasing the Governor's development, optimization, and performance.

## Getting Started
To run this project, make sure you have the necessary hardware and software requirements and clone this repository to your local machine.

## Note
This project is designed for laptops running Ubuntu 20.04 with a USB-A port. 
