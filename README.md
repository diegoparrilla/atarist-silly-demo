# atarist-silly-demo

A sample demo developed with the [atarist-toolkit-docker](https://github.com/diegoparrilla/atarist-toolkit-docker) image

## Introduction

Welcome to the "AtariST Silly Demo", a demo created using the tools available in the [atarist-toolkit-docker](https://github.com/diegoparrilla/atarist-toolkit-docker) project. This demo is written in a combination of C and 68K assembler, and can be built from scratch using the tools provided in the[atarist-toolkit-docker](https://github.com/diegoparrilla/atarist-toolkit-docker) image. The demoscene was a very popular global community of programmers, artists, and musicians who create real-time audio-visual presentations. Demos are often used to showcase the skills and creativity of their creators, as well as the capabilities of a particular platform. I have zero talent and I only write this demo for fun and nostalgia. I hope it can be useful for someone out there.

## Requirements

- An Atari STe computer (or emulator). There are several emulators available for Windows, Linux, and Mac. I recommend [Hatari](http://hatari.tuxfamily.org/), and I'm also a big fan of [MiSTer](https://misterfpga.org/). It should work on any Atari STe with at least 1MB of RAM.

- The [atarist-toolkit-docker](https://github.com/diegoparrilla/atarist-toolkit-docker): You should read first how to install it and how to use it. It's very easy.

- A `git` client. You can use the command line or a GUI client.

- A Makefile compatible with GNU Make.


## Building the demo

Once you have your real Atari STe computer, Hatari emulator or MiSTer Atari STe up and running, you can build the demo using the following steps:

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

4. Copy the `dist/test.tos` file to your Atari STe computer, Hatari emulator or MiSTer Atari ST.

5. Run the demo!

## How to configure Hatari and FFMPEG to record the demo

1. To configure the Hatari emulator, I followed the instructions in the [Dead Hackers Society site](https://www.dhs.nu/videorecording.php).

2. Install FFMPEG. In my case, I installed it with Brew:

```
brew install chromaprint amiaopensource/amiaos/decklinksdk
brew tap homebrew-ffmpeg/ffmpeg
brew install homebrew-ffmpeg/ffmpeg/ffmpeg --with-chromaprint
```

3. I started Hatari adding the following command line parameters:

```
--avi-file ./sillydemo.avi --avi-vcodec png --png-level 1
```

The `--png-level 1` guarantees that the PNG files are not very compressed, which is important to avoid issues in the video in slow computers.

4. After recording the demo, I used the following command to convert the PNG files to a video that can be processed with Quicktime before uploading to YouTube or Twitter:

```
ffmpeg -i sillydemo.avi -vf "scale=1600:1000, pad=1920:1080:160:40:black, format=yuv420p" -sws_flags neighbor -vcodec libx264 -acodec copy sillydemo.mov
```


## Resources 

This "Resources" section contains a list of helpful materials for learning how to build a demo for the Atari ST. This section include tutorials, documentation, and sample code that can assist in the development of a demo for the Atari STe. These materials are intended for developers with varying levels of experience, mostly experienced programmers.

It is important to note that the Atari STe has a unique architecture and programming environment, so it is essential to familiarize yourself with the platform before diving into demo development.

Please feel free to contribute to this list by submitting pull requests with additional resources that you have found helpful in your own Atari STe demo development journey.

### Assembly Language

* [The Atari ST MC68000 Assembly Language Tutorials](https://nguillaumin.github.io/perihelion-m68k-tutorials/index.html) - A series of tutorials on the Atari ST MC68000 Assembly Language. The tutorials are written by Nicolas Guillaumin, and they are available online for free. The tutorials are intended for beginners, but they are also useful for experienced programmers. The tutorials explains some of the unique features of the Atari ST, such as the VBL interrupt, the DMA controller, and sound subsystem. The tutorials also include a series of sample programs that can be used as a starting point for your own projects.

* [MarkeyJester’s Motorola 68000 Beginner’s Tutorial](https://mrjester.hapisan.com/04_MC68/) - A series of tutorials on the Motorola 68000 Assembly Language. The tutorials are written by MarkeyJester, and they are available online for free. The tutorials are intended for beginners, but they are also useful for experienced programmers who want to learn more about the Motorola 68000.

* [VASM manual](http://sun.hasenbraten.de/vasm/release/vasm.html) - The official documentation of the VASM assembler. The VASM assembler is the assembler used in the [atarist-toolkit-docker](https://github.com/diegoparrilla/atarist-toolkit-docker). The documentation is very detailed and it is a great resource for learning how to use the VASM assembler.

* [M68000 Peephole optimizations](https://gist.github.com/flamewing/ad17bf22875be36ad4ae26f159a94f8b) - A list of M68000 of quick optimizations to keep in mind beating the vertical blank. The list is very useful for optimizing your code.

### Atari ST/STE hardware

* [Smooth horizontal scrolling on the STE](http://alive.atari.org/alive12/ste_hwsc.php) - A popular tutorial by Paradox about how to implement smooth horizontal scrolling on the Atari STe. The tutorial explains how to use the DMA controller to implement smooth horizontal scrolling. The tutorial is part of the [Alive 12](http://alive.atari.org/alive12/) magazine, easier to read online compared with other Paradox tutorials sources.

* [Atari STE FAQS](http://alive.atari.org/alive6/ste.php) - A collection of FAQs about how to tame the Atari STe hardware. Another Paradox tutorial. 

* [Programming the blitter](http://s390174849.online.de/ray.tscc.de/blitter.htm) - A tutorial about how to use the blitter of the Atari STe. The tutorial is part of a larger set of tutorials about the Atari ST programming. 

* [4 bitplanes de l'Atari ST](https://www.fxjavadevblog.fr/atari-st-4-bitplanes/) - A French tutorial about how to use the 4 bitplanes of the Atari STe. The tutorial is written by FXJavaDevBlog. Probably the best tutorial about the 4 bitplanes of the Atari ST, something you need to master if you want to create a demo for the Atari STe.

* [Advanced raster interrupt programming](http://thethalionsource.w4f.eu/Artikel/Rasters.htm) - A tutorial about how to use the raster interrupts of the Atari STe. Written by Udo of TEX. Learning from the masters!

### Demo creation

* [Atari ST source code repository](https://github.com/ggnkua/Atari_ST_Sources) - A GitHub repo with a lot of code samples for the Atari ST, STE, Mega ST, TT and Falcon. The code samples are written in C, 68K assembler, and GFA Basic. The code samples are intended for beginners, but they are also useful for experienced programmers.

* [Dead Hackers Society demo creation sources](https://dhs.nu/files.php?t=democreation) - A collection of sources for demo creation. A must!

* [Reservoir Gods library](https://github.com/ReservoirGods/GODLIB) - A library for the Atari ST. The library includes a lot of useful routines for demo creation. The library is written in C, but it also includes a lot of 68K assembler routines. The library is available on GitHub.

* [ASM Samples from NoExtra-Team](https://github.com/NoExtra-Team/Samples) - A collection of sources for demo creation from the NoExtra-Team. Sources are available in 68K assembler, C and also GFA Basic.  
### Tools

* [Motorola 68000 Assembly Extension](https://marketplace.visualstudio.com/items?itemName=clcxce.motorola-68k-assembly) - A Visual Studio Code extension for Motorola 68000 Assembly Language. The extension includes syntax highlighting, snippets, and a debugger.

* [68k Counter](https://marketplace.visualstudio.com/items?itemName=gigabates.68kcounter) - A Visual Studio Code extension for counting the number of cycles and size of the instructions in a 68k assembly file. The extension is useful for optimizing your code.

* [VS Code - C/C++](https://marketplace.visualstudio.com/items?itemName=ms-vscode.cpptools)- The official Visual Studio Code extension for C/C++ development by Microsoft. The extension includes syntax highlighting, snippets, and a debugger.

### Chiptunes

* [Nguillaumin YM Jukebox](https://github.com/nguillaumin/ym-jukebox/tree/master): This repo contains a collection of YM music files. The YM files are available in the `data` folder. The silly demo needs to decompress the ym files with the lha tool. Example: `lha -x chiptune.ym`. The decompresses file should be renamed to `music.ym` and places in the `resources` folder before compiling. You can install `lha` with `brew` in macOS. Use your favourite installation tool to install on Linux.

* [ST sound basics](https://nguillaumin.github.io/perihelion-m68k-tutorials/_of_hearing_that_which_is_spoken.html): A tutorial about how to play YM music files on the Atari ST. The tutorial is written by Nicolas Guillaumin.

## License
This project is licenses under the GNU General Public License v3.0. See the [LICENSE](LICENSE) file for details.
