#include "err.h"
#include "string.h"
#include "unistd.h"
#include "fcntl.h"
#include "stdlib.h"
#include "stdint.h"

int main(int argc, char* argv[])
{
    if (argc < 2)
    {
        errx(1, "Wrong num of args");
    }

    const char* str = argv[1];

    int fd = open(str, O_RDWR);

    if ( fd < 0 )
    {
        err(1, "Could not open file");
    }

    uint32_t bytes[256] = {0};

    uint8_t buf;
    int readBytes = 0;

    while((readBytes = read(fd, &buf, sizeof(buf))) > 0)
    {
        bytes[buf] += 1;
    }

    if (readBytes < 0)
    {
        err(1, "Could not read file");
    }

    if(lseek(fd, 0, SEEK_SET) < 0)
    {
        err(1, "Could not lseek");
    }

    for(int i = 0; i < 256; i++)
    {
        uint8_t currentNum = i;

        for(uint32_t j = 0; j < bytes[i]; j++)
        {
            if(write(fd, &currentNum, sizeof(currentNum)) < 0)
            {
                err(1, "Could not write");
            }
        }
    }

    close(fd);
    exit(0);
}
