#include <stdlib.h>
#include "screen.h"

void initScreenContext(ScreenContext *screenContext)
{
    screenContext->videoAddress = Logbase();   // Get the logical pointer of the video RAM
    screenContext->savedResolution = Getrez(); // Get current resolution
    savePalette(screenContext->savedPalette);  // Save the palette
    //    setFullBlackPalette();                     // put lights off before
}

// saves the current palette into a buffer (works only in supervisor mode)
void savePalette(__uint16_t *paletteBuffer)
{
    memcpy(paletteBuffer, PALETTE_ADDRESS, sizeof(__uint16_t) * 16); // 16 colors, 16 bits each.
}

// restores the saved resolution and its palette
void restoreResolutionAndPalette(ScreenContext *screenContext)
{
    Setscreen((*screenContext).videoAddress, (*screenContext).videoAddress, (*screenContext).savedResolution);
    Setpalette((*screenContext).savedPalette);
}

void setFullBlackPalette()
{
    for (int i = 0; i < 16; i++)
    {
        Setcolor(i, 0x000);
    }
}

void initLowResolution(__uint16_t palette[16])
{
    Setscreen(-1, -1, LOW_RES);
    Setpalette(palette);
}

void restoreScreenContext(ScreenContext *screenContext)
{
    restoreResolutionAndPalette(screenContext);
}
