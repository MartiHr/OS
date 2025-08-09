#include <sys/stat.h>
#include "err.h"
#include "fcntl.h"
#include "stdlib.h"
#include "unistd.h"
#include "stdint.h"
#include "errno.h"

struct pair {
    uint32_t x;
    uint32_t y;
};

int fds[3] = { -1, -1, -1 };

void closeAll(void)
{
    int savedErrno = errno;

    for(int i = 0; i < 3; i++)
    {
        if(fds[i] >= 0)
        {
            close(fds[i]);
        }
    }

    errno = savedErrno;
}

int main(int argc, char* argv[])
{
    if (argc != 4)
        errx(1, "ERROR: Arg count");

    fds[0] = open(argv[1], O_RDONLY);

    if(fds[0] < 0)
    {
        err(2, "Cannot open file");
    }


    fds[1] = open(argv[2], O_RDONLY);
    if(fds[1] < 0)
    {
        closeAll();
        err(2, "Could not open file");
    }


    fds[1] = open(argv[2], O_RDONLY);
    if(fds[1] < 0)
    {
        closeAll();
        err(2, "Could not open file");
    }

    struct stat st;

    if(fstat(fds[0], &st) < 0)
    {
        closeAll();
        err(3, "Could not stat file %s", argv[1]);
    }

    if (st.st_size % sizeof(struct pair) != 0)
    {
        closeAll();
        errx(4, "Input file must contain whole pairs (size must be divisible by 8)");
    }

    fds[2] = open(argv[3], O_WRONLY | O_CREAT | O_TRUNC, 0644);

    if(fds[2] < 0)
    {
        closeAll();
        err(5, "Erro output file");
    }

   struct pair p;
   int bytesRead;

    while((bytesRead = read(fds[0], &p, sizeof(p))) == sizeof(p))
    {
        int offset = p.x * sizeof(uint32_t);

        if(lseek(fds[1], offset, SEEK_SET) < 0)
        {
            closeAll();
            err(1, "lseek failed");
        }

        for(uint32_t i = 0; i < p.y; i++)
        {
            uint32_t value;
   int rBytes = read(fds[1], &value, sizeof(value));

            if (rBytes != sizeof(value))
            {
                closeAll();
                err(1, "Failed to read exactly 4 bytes");
            }

            if(write(fds[2], &value, sizeof(value) != sizeof(value)))
            {
                closeAll();
                err(1, "Failed to write 4 bytes");
            }
        }

    }

    if (bytesRead < 0)
    {
        closeAll();
        err(9, "Error while reading input pairs from file: %s", argv[1]);
    }
    closeAll();
}