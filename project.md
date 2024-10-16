# Project
As part of Fuzzing Lab, you will get to participate in a quarter long project involving fuzzing **real-world software**.
Unlike the exercises, this project will involve you to apply the knowledge you learned on a target of your choice.
For more information about the project requirements, please check out the [slides from the first week](README.md).
There are three potential types of targets you can pick from which are listed below.

Once you have decided on a group and team members, please fill out [this form](https://forms.gle/j8Qe5At51cmj1HfZ9) as part of the project proposal.
We are aiming to form groups of roughly 2-3 members.

## Option 1: Research a Known Vulnerability
Honggfuzz has been used to find many vulnerabilities in the past.
This project will involve learning more about how security researchers used Honggfuzz to find vulnerabilities based on known CVEs.
You will be working on fuzzing targets on versions known to be vulnerable and trying to reproduce the CVE.
The following is the list of preapproved targets:

- libiptcdata: https://github.com/ianw/libiptcdata
- libraw: https://github.com/LibRaw/LibRaw
- libtiff: https://gitlab.com/libtiff/libtiff

The following involve standalone fuzzing if groups are interested in working on them:
- htmldoc: https://github.com/michaelrsweet/htmldoc
- md4c: https://github.com/mity/md4c
- opendetex: https://github.com/pkubowicz/opendetex
- xfig: https://github.com/hhoeflin/xfig
- atasm: https://github.com/CycoPH/atasm

## Option 2: Fuzz for New Vulnerabilities
As a more ambitious goal for your project, you can try fuzzing a target that has **not** been fuzzed before. This project will involve researching an open-source software library or tool that has not been fuzzed before and working on setting up a fuzzing environment for it. With this project, you will delve more in depth to understanding how vulnerabilities are found in real-world software. A list of preapproved targets is below:

- yaml-cpp: https://github.com/jbeder/yaml-cpp
- libfyaml: https://github.com/pantoniou/libfyaml
- xml.c: https://github.com/ooxi/xml.c
- tomlc99: https://github.com/cktan/tomlc99
- ctoml: https://github.com/evilncrazy/ctoml
- tinyxml2: https://github.com/leethomason/tinyxml2
- json-parser: https://github.com/json-parser/json-parser
- jsonxx: https://github.com/hjiang/jsonxx
- Yams: https://github.com/jpsim/Yams
- csv-parser: https://github.com/vincentlaucsb/csv-parser
- myhtml: https://github.com/lexborisov/myhtml
- podofo: https://github.com/podofo/podofo

## Option 3: Propose Your Own Project
Some groups may be interested in working on a project or target that is not listed above (for example, fuzzing with a different fuzzer besides Honggfuzz).
We allow groups to work on whatever ideas that interest them but we want to ensure that the project is feasible so that each group has the best experience!
If you are interested in this option, **please contact an officer** to discuss your project idea before submitting the proposal form.
