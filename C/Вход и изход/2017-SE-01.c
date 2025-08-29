#include "stdint.h"
#include "unistd.h"
#include "fcntl.h"
#include "err.h"
#include "string.h"
#include <sys/stat.h>

int main(int argc, char* argv[])
{
    if(argc != 4)
    {
        errx(1, "Wrong num of args");
    }

    const char* file1 = argv[1];
    const char* file2 = argv[2];
    const char* file3 = argv[3];

    int fd1 = open(file1, O_RDONLY);

    if (fd1 < 0)
    {
        err(1, "Could not open file1");
    }

    int fd2 = open(file2, O_RDONLY);

    if (fd2 < 0)
    {
        close(fd1);
        err(1, "Could not open file2");
    }

    struct stat s1;
    struct stat s2;

    if(fstat(fd1, &s1) < 0)
    {
        err(1, "Could not fstat");
    }

    if(fstat(fd2, &s2) < 0)
    {
        err(1, "Could not fstat");
    }

    uint32_t size1 = s1.st_size;
    uint32_t size2= s2.st_size;

    if (size1 != size2)
    {
        errx(4, "files are not consistent %s, %s", file1, file2);
    }

    struct triple
    {
        uint16_t offset;
        uint8_t b1;
        uint8_t b2;
    };

    int fd3 = open(file3, O_WRONLY | O_CREAT | O_TRUNC, 0644);

    if (fd3 < 0)
    {
        close(fd1);
        close(fd2);
        err(1, "Could not open file 3");
    }


    int readSize1 = -1;
    int readSize2 = -1;

    struct triple tr;

    for(tr.offset = 0; tr.offset < size1; tr.offset++)
    {
        if((readSize1 = read(fd1, &tr.b1, sizeof(tr.b1))) != sizeof(tr.b1))
        {
            close(fd1);
            close(fd2);
            close(fd3);
            err(1, "Err reading");
        }

        if((readSize2 = read(fd2, &tr.b2, sizeof(tr.b2))) != sizeof(tr.b2))
        {
            close(fd1);
            close(fd2);
            close(fd3);
            err(1, "Err reading");
        }

        if(tr.b1 != tr.b2)
        {
            if(write(fd3, &tr, sizeof(tr)) < 0)
            {
                close(fd1);
                close(fd2);
                close(fd3);

                err(1, "Error writing");
            }
        }
    }

    if (readSize1 < 0 || readSize2 < 0)
    {
        close(fd1);
        close(fd2);
        close(fd3);
        err(1, "Error while reading");
    }

    close(fd1);
    close(fd2);
    close(fd3);
}
