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

#### Select vulnerbilities

This test suite allows you to select the vulnerabilities to be tested at first.

Following combinations are supported:

| Options     | Vulnerabilities to be tested    |
| ----------- | ------------------------------- |
| all         | All vulnerabilities             |
| meltdown    | All Meltdown vulnerabilities    |
| spectre     | All Spectre vulnerabilities     |
| spectre_btb | All Spectre_BTB vulnerabilities |
| spectre_pht | All Spectre_PHT vulnerabilities |
| spectre_rsb | All Spectre_RSB vulnerabilities |

You can also use multi_parameters to select specific vulnerabilities and separate them with spaces:

| Options | Vulnerabilities to be tested | Options    | Vulnerabilities to be tested |
| ------- | ---------------------------- | ---------- | ---------------------------- |
| ac      | Meltdown_AC                  | btb_sa_ip  | Spectre_BTB_sa_ip            |
| br      | Meltdown_BR                  | btb_sa_oop | Spectre_BTB_sa_oop           |
| de      | Meltdown_DE                  | btb_ca_ip  | Spectre_BTB_ca_ip            |
| gp      | Meltdown_GP                  | btb_ca_oop | Spectre_BTB_ca_oop           |
| nm      | Meltdown_NM                  | pht_sa_ip  | Spectre_PHT_sa_ip            |
| p       | Meltdown_P                   | pht_sa_oop | Spectre_PHT_sa_oop           |
| pk      | Meltdown_PK                  | pht_ca_ip  | Spectre_PHT_ca_ip            |
| rw      | Meltdown_RW                  | pht_ca_oop | Spectre_PHT_ca_oop           |
| ss      | Meltdown_SS                  | rsb_sa_ip  | Spectre_RSB_sa_ip            |
| ud      | Meltdown_UD                  | rsb_sa_oop | Spectre_RSB_sa_oop           |
| us      | Meltdown_US                  | rsb_ca_ip  | Spectre_RSB_ca_ip            |
| stl     | Spectre_STL                  | rsb_ca_oop | Spectre_RSB_ca_oop           |

Default option is "all" for testing all vulnerabilities.

#### Output valid PoCs
#### To be added...

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
sudo apt-get install libelf-dev build-essential pkg-config bison flex libssl-dev libelf-dev bc
sudo apt-get purge libc6-dev
sudo apt-get install libc6-dev
sudo apt-get install libc6-dev-i386
sudo apt-get install build-essential
sudo apt-get install seccomp
sudo apt-get install libseccomp-dev
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
