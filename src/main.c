#include <sys/types.h>
#include <stdio.h>
#include <time.h>

extern void asm_display_picture();
extern void asm_display_picture_fast();
extern void asm_populate_bin_ptrs();
extern void asm_main_loop();
extern __uint32_t asm_get_machine_type();
extern __uint32_t asm_get_memory_size();

extern __uint32_t *font_large_ptr;
extern __uint32_t *font_small_ptr;
extern __uint32_t *c23_logo_ptr;
extern __uint32_t *screen;
extern __uint32_t *picture;
extern __uint32_t *font_large_ready;
extern __uint32_t *font_small_ready;
extern __uint32_t *c23_logo_ready;

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
    const int WORDS_EMPTY_BUFFER_PER_CHAR = 4;

    int linear = 0;
    for (int char_lines = 0; char_lines < (NUMBER_OF_CHARS / NUMBER_OF_CHARS_PER_LINE) + 1; char_lines++)
    {
        for (int chrs = 0; chrs < NUMBER_OF_CHARS_PER_LINE; chrs++)
        {
            for (int lines = 0; lines < LINES_PER_CHAR; lines++)
            {
                if ((char_lines == (NUMBER_OF_CHARS / NUMBER_OF_CHARS_PER_LINE)) && (chrs == 7))
                    return;
                for (int idx = 0; idx < WORDS_EMPTY_BUFFER_PER_CHAR; idx++)
                {
                    font_ready[linear + idx] = 0;
                }
                for (int idx = 0; idx < WORDS_WIDTH_PER_CHAR; idx++)
                {
                    int offset = (char_lines * SCREEN_WORDS_WIDTH * LINES_PER_CHAR) +
                                 (chrs * WORDS_WIDTH_PER_CHAR) +
                                 (lines * SCREEN_WORDS_WIDTH) + idx;
                    font_ready[linear + WORDS_EMPTY_BUFFER_PER_CHAR + idx] = picture[offset];
                    picture[offset] = 0xFFFF;
                }
                linear += WORDS_WIDTH_PER_CHAR + WORDS_EMPTY_BUFFER_PER_CHAR;
            }
        }
    }
}

void AlignFont16x16(__uint16_t picture[], __uint16_t font_ready[])
{
    const int LINES_PER_CHAR = 16;
    const int WORDS_WIDTH_PER_CHAR = 1;
    const int SCREEN_WORDS_WIDTH = 80;
    const int NUMBER_OF_CHARS = 40;
    const int NUMBER_OF_CHARS_PER_LINE = 20;
    const int WORDS_EMPTY_BUFFER_PER_CHAR = 0;
    const int SKIP_PLANES_WORDS = 3;

    int linear = 0;
    for (int char_lines = 0; char_lines < (NUMBER_OF_CHARS / NUMBER_OF_CHARS_PER_LINE); char_lines++)
    {
        for (int chrs = 0; chrs < NUMBER_OF_CHARS_PER_LINE; chrs++)
        {
            for (int lines = 0; lines < LINES_PER_CHAR; lines++)
            {
                for (int idx = 0; idx < WORDS_WIDTH_PER_CHAR; idx++)
                {
                    int offset = (char_lines * SCREEN_WORDS_WIDTH * LINES_PER_CHAR) +
                                 (chrs * (WORDS_WIDTH_PER_CHAR + SKIP_PLANES_WORDS)) +
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

void AlignLogo320x59(__uint16_t picture[], __uint16_t logo_ready[])
{
    const int SCREEN_WORDS_WIDTH = 80;
    const int LOGO_WORDS_WIDTH = 80;
    const int LOGO_LINES = 58;
    const int SKIP_PLANES_WORDS = 4;
    const int SPRITE_PLANES = 3;
    const int SCREEN_PLANES = 4;
    const int SCREEN_WORDS_PER_PLANE_WIDTH = 18;

    int linear = 0;
    for (int lines = 0; lines < LOGO_LINES; lines++)
    {
        for (int idx = 0; idx < SCREEN_WORDS_PER_PLANE_WIDTH; idx++)
        {
            int offset = 4 + (lines * SCREEN_WORDS_WIDTH) + (idx * SCREEN_PLANES) + 0;
            int firstPlane = picture[offset + 0];
            int secondPlane = picture[offset + 1];
            int thirdPlane = picture[offset + 2];
            int fourthPlane = picture[offset + 3];
            int spriteOffset = (lines * SCREEN_WORDS_PER_PLANE_WIDTH * SPRITE_PLANES) + (idx * SPRITE_PLANES);
            logo_ready[spriteOffset + 0] = firstPlane;
            picture[offset] = 0xFFFF;
            logo_ready[spriteOffset + 1] = secondPlane;
            picture[offset + 1] = 0xFFFF;
            logo_ready[spriteOffset + 2] = thirdPlane;
            picture[offset + 2] = 0xFFFF;
            //            logo_ready[spriteOffset + 3] = fourthPlane;
            picture[offset + 3] = 0xFFFF;
        }
    }
}

void ShowMachineType(__uint32_t m_type)
{
    switch (m_type)
    {
    case 0:
        printf("Machine type: ATARI ST\r\n");
        break;
    case 1:
        printf("Machine type: ATARI STe\r\n");
        break;
    case 2:
        printf("Machine type: ATARI TT\r\n");
        break;
    case 3:
        printf("Machine type: ATARI Falcon030\r\n");
        break;
    case 4:
        printf("Machine type: Milan\r\n");
        break;
    default:
        printf("Machine type: Unknown\r\n");
        break;
    }
}

//================================================================
// Main program
void run()
{
    __uint32_t machine_type = asm_get_machine_type() >> 16;
    __uint32_t memory_size = asm_get_memory_size();

    printf("\r");
    printf("THE SILLY DEMO - 1990-2023 Logronoide\r\n");
    printf("=====================================\r\n");
    ShowMachineType(machine_type);
    printf("Memory size: %d KB\r\n", memory_size / 1024);
    printf("\r\n");
    if (_DEBUG)
    {
        printf("asm_main_loop: %p\r\n", asm_main_loop);
    }
    printf("\r\n");
    printf("\r\n");
    printf("\r\n");
    printf("\r\n");
    printf("\r\n");
    printf("\r\n");
    printf("\r\n");
    printf("\r\n");
    printf("\r\n");
    printf("\r\n");
    printf("\r\n");
    printf("\r\n");
    int valid_machine = 1;
    if (machine_type != 1)
    {
        printf("This demo is only for STE machines.\r\n");
        valid_machine = 0;
    }
    if (memory_size < 2 * 1024 * 1024 - 32768)
    {
        printf("This demo needs at least 2 MB of memory.\r\n");
        valid_machine = 0;
    }
    if (!valid_machine)
    {
        printf("Press any key to exit.\r\n");
        getchar();
    }
    else
    {
        printf("Press any key to start.\r\nPress ESC to exit the demo.\r\n");
        asm_populate_bin_ptrs();
        getchar();
        asm_main_loop();
    }

    //    picture = c23_logo_ptr;
    //    asm_display_picture();
    //    AlignLogo320x59((__uint16_t *)screen, (__uint16_t *)c23_logo_ready);

    //    picture = font_small_ptr;
    //    asm_display_picture();
    //    AlignFont16x16((__uint16_t *)screen, (__uint16_t *)font_small_ready);

    //    picture = font_large_ptr;
    //    asm_display_picture();
    //    AlignFont32x25((__uint16_t *)screen, (__uint16_t *)font_large_ready);

    //    FILE *write_ptr;

    //    write_ptr = fopen("IMAGES.BIN", "wb");                             // w for write, b for binary
    //    fwrite(font_large_ready, 28800 + 1280 + 6372 + 512, 1, write_ptr); // write bytes from our buffer
}

//================================================================
// Standard C entry point
int main(int argc, char *argv[])
{
    // switching to supervisor mode and execute run()
    // needed because of direct memory access for reading/writing the palette
    Supexec(&run);
}
