#==============================================================================
#	Build colourmaps
#==============================================================================

AGTBIN=/Users/diego/mister_wkspc/agtools/bin/Darwin/x86_64

# final colourmaps are precious - generate rarely, keep under source control
OUT=./resources
IN=./resources
# working directory
GENTEMP=./build
mkdir -p ${GENTEMP}

PCS="${AGTBIN}/pcs -dg -cd ste -pc 4 -ccmode 5 -ccincap 65535 -ccfields 1 -ccrounds 32 -ccthreads 4"

#==============================================================================

# create a superpalette from all art assets (only needs done once, or after significant art changes)
# WARNING: this is a compute-intensive step. it takes time. best disabled once the palette is produced.

#TUNING="-ccpopctrl 0.5 -ccdodge 1110 -ccl 0=0:0:0 -ccl 1=b:7:b -ccl 2=9:5:9 -ccl 3=a:0:a -ccl 4=0:1:F -ccl 5=3:0:3 -ccl 6=F:a:c -ccl 7=6:3:6"
#TUNING="-ccpopctrl 0.5 -ccdodge 1110 -ccl 0=0:0:0 -ccl 7=F:F:F"
#TUNING="-ccpopctrl 0.5 -ccdodge 0111 -ccl 0=0:0:0 -ccl 1=6:3:6 -ccl 2=7:5:a -ccl 3=a:5:8 -ccl 4=c:7:b -ccl 5=3:0:3 -ccl 6=d:9:b -ccl 7=f:9:c -ccl 8=8:8:8 -ccl 15=F:F:F"
TUNING="-ccpopctrl 0.8 -ccdodge 0111 -ccl 0=0:0:0 -ccl 7=F:F:F -ccl 8=8:8:8 -ccl 9=8:8:8 -ccl 10=8:8:8 -ccl 11=8:8:8 -ccl 12=8:8:8 -ccl 13=8:8:8 -ccl 14=8:8:8  -ccl 15=F:F:F"

#${PCS} -ccout ${OUT}/colmap ${TUNING} ${IN}/uridium-zinc-c64.png
${PCS} -ccout ${OUT}/colmap ${TUNING} ${IN}/FONTC23.PNG
