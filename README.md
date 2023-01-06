# atarist-silly-demo

A sample demo developed with the [atarist-toolkit-docker](https://github.com/diegoparrilla/atarist-toolkit-docker) image

## Introduction

Welcome to the "AtariST Silly Demo", a demo created using the tools available in the [atarist-toolkit-docker](https://github.com/diegoparrilla/atarist-toolkit-docker) project. This demo is written in a combination of C and 68K assembler, and can be built from scratch using the tools provided in the[atarist-toolkit-docker](https://github.com/diegoparrilla/atarist-toolkit-docker) image. The demoscene was a very popular global community of programmers, artists, and musicians who create real-time audio-visual presentations. Demos are often used to showcase the skills and creativity of their creators, as well as the capabilities of a particular platform. I have zero talent and I only write this demo for fun and nostalgia. I hope it can be useful for someone out there.

## Requirements

- An Atari ST computer (or emulator). There are several emulators available for Windows, Linux, and Mac. I recommend [Hatari](http://hatari.tuxfamily.org/), and I'm also a big fan of [MiSTer](https://misterfpga.org/). It should work on any Atari ST with at least 1MB of RAM.

- The [atarist-toolkit-docker](https://github.com/diegoparrilla/atarist-toolkit-docker): You should read first how to install it and how to use it. It's very easy.

- A `git` client. You can use the command line or a GUI client.

- A Makefile compatible with GNU Make.


## Building the demo

Once you have your real Atari ST computer, Hatari emulator or MiSTer Atari ST up and running, you can build the demo using the following steps:

1. Clone this repository:

```
$ git clone https://github.com/diegoparrilla/atarist-silly-demo
```

2. Export the `ST_WORKING_FOLDER` environment variable with the absolute path of the folder where you cloned the repository:

```
export ST_WORKING_FOLDER=<ABSOLUTE_PATH_TO_THE_FOLDER_WHERE_YOU_CLONED_THE_REPO>
```

3. Build the demo. Enter the `atarist-silly-demo` folder and run the `make` script:

```
cd atarist-silly-demo
make
```

4. Copy the `dist/test.tos` file to your Atari ST computer, Hatari emulator or MiSTer Atari ST.

5. Run the demo!

