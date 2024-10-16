# Project

As part of Fuzzing Lab, you will get to participate in a quarter-long project where you will use the skills that you've learned to fuzz a new target of your choice.
For more information about the project requirements, please check out the [slides from the first week](https://l.acmcyber.com/fuzzing-lab-1).
The three types of targets that you can pick from are listed below.

Once you have formed a group and chosen a target, please fill out [this form](https://forms.gle/j8Qe5At51cmj1HfZ9) as part of the project proposal.
Your groups should have around two to three members.

## Option 1: Fuzz for New Vulnerabilities

For this option, your goal is to fuzz something that hasn't been fuzzed before, and you might find a new vulnerability if you're lucky.
You will need to research an open-source library and write a fuzzing harness for it.
Here's a list of targets that we recommend:

- yaml-cpp: https://github.com/jbeder/yaml-cpp
- libfyaml: https://github.com/pantoniou/libfyaml
- xml.c: https://github.com/ooxi/xml.c
- tomlc99: https://github.com/cktan/tomlc99
- ctoml: https://github.com/evilncrazy/ctoml
- tinyxml2: https://github.com/leethomason/tinyxml2
- json-parser: https://github.com/json-parser/json-parser
- jsonxx: https://github.com/hjiang/jsonxx
- myhtml: https://github.com/lexborisov/myhtml
- podofo: https://github.com/podofo/podofo

We've chosen targets that have probably not been fuzzed before, and aren't too hard to fuzz with the skills that you will learn in this lab.
Please talk to us if you want to choose something not on this list.

## Option 2: Research a Known Vulnerability

Fuzzers have been used to find many vulnerabilities in the past.
For this option, you will fuzz a version of the target that is known to have at least one vulnerability and your goal is to find a test case that reproduces a known vulnerability.
Here's the list of targets for this option:

- libiptcdata: https://github.com/ianw/libiptcdata
- libraw: https://github.com/LibRaw/LibRaw
- libtiff: https://gitlab.com/libtiff/libtiff

Additionally, we have some targets that are standalone executables rather than libraries, so you won't need to write your own fuzzing harness.
You can try to fuzz these if you want additional practice with the basic fuzzing concepts, but we strongly recommend that you choose something from the other lists since writing fuzzing harnesses is an important skill that we want you to learn.

- htmldoc: https://github.com/michaelrsweet/htmldoc
- md4c: https://github.com/mity/md4c
- opendetex: https://github.com/pkubowicz/opendetex
- xfig: https://github.com/hhoeflin/xfig
- atasm: https://github.com/CycoPH/atasm

## Option 3: Propose Your Own Project

Some groups may be interested in working on a project or target that is not listed above (for example, using a fuzzer other than Honggfuzz).
We allow groups to work on other fuzzing-related projects, but we want to ensure that the project is feasible so that each group has the best experience!
If you are interested in this option, **please contact an officer** to discuss your project idea before submitting the proposal form.
