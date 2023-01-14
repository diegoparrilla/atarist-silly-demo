#include <sys/types.h>
#include <stdio.h>
#include <time.h>

#include "screen.h"

extern void asm_display_picture();
extern void asm_display_picture_fast();
extern void asm_populate_bin_ptrs();
extern void asm_main_loop();

extern __uint32_t *font_large_ptr;
extern __uint32_t *font_small_ptr;
extern __uint32_t *c23_logo_ptr;
extern __uint32_t *screen;
extern __uint32_t *picture;
extern __uint32_t *font_large_ready;

__uint16_t *GetDegasPalette(__uint16_t picture[], __uint16_t *palette)
{
    for (int i = 1; i < 17; i++)
    {
        palette[i - 1] = picture[i];
    }
}

void DisplayDegasPicture(__uint16_t *vaddr, __uint16_t picture[])
{
    for (int i = 18; i < 16019; i++)
    {
        vaddr[i - 17] = picture[i];
    }
}

void AlignFont32x25(__uint16_t picture[], __uint16_t font_ready[])
{
    const int LINES_PER_CHAR = 25;
    const int WORDS_WIDTH_PER_CHAR = 8;
    const int SCREEN_WORDS_WIDTH = 80;
    const int NUMBER_OF_CHARS = 48;
    const int NUMBER_OF_CHARS_PER_LINE = 10;
    const int WORDS_EMPTY_BUFFER_PER_CHAR = 0;

    int linear = 0;
    for (int char_lines = 0; char_lines < (NUMBER_OF_CHARS / NUMBER_OF_CHARS_PER_LINE) + 1; char_lines++)
    {
        for (int chrs = 0; chrs < NUMBER_OF_CHARS_PER_LINE; chrs++)
        {
            for (int lines = 0; lines < LINES_PER_CHAR; lines++)
            {
                if ((char_lines == (NUMBER_OF_CHARS / NUMBER_OF_CHARS_PER_LINE)) && (chrs == 7))
                    return;
                for (int idx = 0; idx < WORDS_WIDTH_PER_CHAR; idx++)
                {
                    int offset = (char_lines * SCREEN_WORDS_WIDTH * LINES_PER_CHAR) +
                                 (chrs * WORDS_WIDTH_PER_CHAR) +
                                 (lines * SCREEN_WORDS_WIDTH) + idx;
                    font_ready[linear + idx] = picture[offset];
                    picture[offset] = 0xFFFF;
                }
                for (int idx = 0; idx < WORDS_EMPTY_BUFFER_PER_CHAR; idx++)
                {
                    font_ready[linear + WORDS_WIDTH_PER_CHAR + idx] = 0;
                }
                linear += WORDS_WIDTH_PER_CHAR + WORDS_EMPTY_BUFFER_PER_CHAR;
            }
        }
    }
}

//================================================================
// Main program
void run()
{

    __uint16_t palette[16];
    __uint16_t palette_simple[16];
    clock_t start;
    float cpu_time_used;

    asm_populate_bin_ptrs();

    printf("font_large_ptr: %p\r\n", font_large_ptr);
    printf("font_small_ptr: %p\r\n", font_small_ptr);
    printf("c23_logo_ptr: %p\r\n", c23_logo_ptr);
    printf("font_large_ready: %p\r\n", font_large_ready);

    printf("font_large_ptr: %p\r\n", font_large_ptr);
    printf("font_small_ptr: %p\r\n", font_small_ptr);
    printf("c23_logo_ptr: %p\r\n", c23_logo_ptr);
    printf("font_large_ready: %p\r\n", font_large_ready);

    GetDegasPalette((__uint16_t *)font_large_ptr, palette);
    for (int i = 0; i < 8; i++)
    {
        palette_simple[i] = palette[i];
    }
    for (int i = 0; i < 8; i++)
    {
        palette_simple[i + 8] = palette[i];
    }
    palette_simple[8] = 0x0222; // Change the color of the tile

    for (int i = 0; i < 16; i++)
    {
        printf("palette[%d]: %x\r\n", i, palette_simple[i]);
    }

    printf("\r\n");
    printf("asm_main_loop: %p\r\n", asm_main_loop);
    printf("\r\n");
    printf("ESC to exit\r\n");
    printf("Press 1 to 10 for different effects\r\n");
    getchar();

    ScreenContext *screenContext = malloc(sizeof(ScreenContext));
    initScreenContext(screenContext);

    initLowResolution(palette_simple);

    screen = screenContext->videoAddress;

    picture = font_large_ptr;
    asm_display_picture();
    AlignFont32x25((__uint16_t *)screen, (__uint16_t *)font_large_ready);

    asm_main_loop();

    // start = clock();
    // asm_display_picture_fast();
    // printf("Time: %fs\r\n", ((float) (clock() - start)) / (CLOCKS_PER_SEC));
    // getchar();

    // picture = font_small_ptr;
    // GetDegasPalette((__uint16_t *) picture, palette);
    // Setpalette(palette);
    // asm_display_picture_fast();
    // getchar();

    // picture = c23_logo_ptr;
    // GetDegasPalette((__uint16_t *) picture, palette);
    // Setpalette(palette);
    // asm_display_picture_fast();
    // getchar();

    // Restoring the resolution and its palette
    restoreScreenContext(screenContext);

    free(screenContext);
}

//================================================================
// Standard C entry point
int main(int argc, char *argv[])
{
    // switching to supervisor mode and execute run()
    // needed because of direct memory access for reading/writing the palette
    Supexec(&run);
}
