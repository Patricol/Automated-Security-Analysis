# Automated Security Analysis

This tool was created for research purposes, as a part of my paper, [Simple Scripts Evaluate Android Application Security](https://github.com/Patricol/Automated-Security-Analysis/blob/master/Simple%20Scripts%20Evaluate%20Android%20Application%20Security%20-%20Patrick%20Collins.pdf).

For the research paper, 100 applications were examined. 50 were pulled from the Google Play Store randomly by a script. 50 were chosen from the Google Play Store's selection of IOT apps.

Sample output is available; describing vulnerabilities found in:
* [Angry Birds Star Wars 2](https://github.com/Patricol/Automated-Security-Analysis/blob/master/sample_output/com.rovio.angrybirdsstarwarsii.ads-output.txt)
* [Nokia Smart Home](https://github.com/Patricol/Automated-Security-Analysis/blob/master/sample_output/com.nokia.dhbu.smartHome-output.txt)


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

## Made Using
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
