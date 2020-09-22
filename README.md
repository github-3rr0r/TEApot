# Transient Execution Attack Pot

TEApot(Transient Execution Attack pot) is a project used to evaluate whether your system is affected by Meltdown and Spectre. My goal is to build a easy-to-use(hard to implement) and configurable transient attack test suite.

This project is mainly based on project [Transient Fail](https://github.com/IAIK/transientfail) developed by [IAIK](https://www.iaik.tugraz.at/). More information will be found on their paper [A Systematic Evaluation of Transient Execution Attacks and Defenses](http://cc0x1f.net/publications/transient_sytematization.pdf).

## Features

### Supported Platform

#### Operating System

Linux with gcc and other dependent libraries.

#### CPU

x86 and arm64 are supported.

### Supported Vulnerablities

Meltdown-like and Spectre-like vulnerabilities, more information will be also found on paper [A Systematic Evaluation of Transient Execution Attacks and Defenses](http://cc0x1f.net/publications/transient_sytematization.pdf).

### Configurable features

1. Which vulnerbility do you want to test?
2. Do you want to output the PoC code that successfully exploited the vulnerability?
3. To be added...

## Repository Structure

* ```lib```: Global libraries;
* ```libcache```: Cache operation libraries;
* ```libpte```:  [PTEditor](https://github.com/misc0110/PTEditor) developed by Michael Schwarz that allows manipulation of paging structures via a Linux kernel module;
* ```meltdown```: PoC of Meltdown-like vulnerabilities;
* ```spectre```: PoC of Spectre-like vulnerabilities;
* ```Makefile```: Makefile of this test suite;
* ```run.sh```: Main entry of this test suite;
* ```README.md```: The file you are reading!

## Usage

0. Some preparation

```shell
# to-do
```

1. Clone this repository

```shell
git clone https://github.com/Mashiro1995/TEApot.git
```

2. Make

```shell
make
```

3. Grant execution permissions and run!

```shell
chmod +x run.sh
./run.sh
```

```shell
# This project was originally call Transient Execution Attack Test Suite, but the abbreviation was really cursed. I've also tried TAT, a cute name, but full name without "execution" seems unreasonable. So after careful consideration, I decided to use "TEApot" as the name of the project. Both "pot" and "suite" are containers for something. 
```
