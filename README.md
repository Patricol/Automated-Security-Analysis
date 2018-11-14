# Automated Security Analysis

This tool was created for research purposes, as a part of my paper, [Simple Scripts Evaluate Android Application Security](https://github.com/Patricol/Automated-Security-Analysis/blob/master/Simple Scripts Evaluate Android Application Security - Patrick Collins.pdf).

## Functionality
* searches through disassembled android applications to find
  * security vulnerabilities, like:
    * SSL API misuse
    * unprotected interfaces
  * potentially dangerous combinations of requested permissions
* creates detailed output
  * shows the context around the potential vulnerabilities it finds
  * shows where the functions or classes containing the concerning code are invoked

## Setup
* I created the main script (analyze.sh) and most of the helper scripts so they could execute on a fresh installation of Ubuntu 16.04 with no additional packages installed.
  * However, apk files need to be disassembled with [apktool](https://ibotpeaches.github.io/Apktool/).
    * disassemble.sh automates this if apktool is installed.
* The helper scripts are unnecessary; you can just run analyze.sh in a disassembled app's folder.

## Uses
  * bash scripting
  * common utilities like:
    * find
    * grep
    * awk
    * sed
  * no external libraries
  * no third party programs

## Helper Scripts
* The helper scripts expect to find disassembled apps' folders in ./apps/
* run.sh
  * Creates and executes copies of analyze.sh for each application.
    * Uses xargs to run them in parallel across multiple CPU cores.
  * Once all analyze.sh scripts finish, it:
    * removes the copies of analyze.sh
    * moves and renames the output files for convenience
* disassemble.sh
  * Uses apktool to disassemble any apk files in the apps folder.
* clear-output.sh
  * Deletes all output files.
  * Also removes copies of analyze.sh that may be left behind if run.sh is stopped midway.
* read-outputs.sh
  * Prints all output files to the terminal.
  * Recommended to run as "./read-outputs.sh | less" for easier reading.
