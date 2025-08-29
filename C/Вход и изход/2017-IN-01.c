#include <stdbool.h>
#include <string.h>
#include <sys/stat.h>
#include <stdint.h>
#include <fcntl.h>
#include <unistd.h>
#include <err.h>
#include <errno.h>

int fds[4] = { -1, -1, -1, -1 };

void closeAll(void)
{
    int currErrno = errno;

    for(int i = 0; i < 4; i++)
    {
        if(fds[i] >= 0)
        {
            close(fds[i]);
        }
    }

    errno = currErrno;
}

int readSafe(const char* filename)
{
    int fd = open(filename, O_RDONLY);

    if(fd < 1)
    {
        err(1, "Could not open for reading");
    }

    return fd;
}

int writeSafe(const char* filename)
{
    int fd = open(filename, O_WRONLY | O_CREAT | O_TRUNC, 0644);

    if(fd < 1)
    {
        err(1, "Could not open for reading");
    }

    return fd;
}

bool startsWithCapital(const char* buff)
{
    char ch = *buff;

    return ch >= 'A' && ch <= 'Z';
}

typedef struct
{
    uint16_t offset;
    uint8_t length;
    uint8_t padding;
} Triple;

int main(int argc, char* argv[])
{

    if(argc != 5)
    {
        errx(1, "Wrong num of args");
    }

    for(int i = 0; i < 4; i++)
    {
        fds[i] = -1;
    }

    const char* firstDat = argv[1];
    const char* firstIdx = argv[2];
    const char* secondDat = argv[3];
    const char* secondIdx = argv[4];

    fds[0] = readSafe(firstDat);
    fds[1] = readSafe(firstIdx);
    fds[2] = writeSafe(secondDat);
    fds[3] = writeSafe(secondIdx);

    struct stat st;
    if(fstat(fds[0], &st) < 0)
    {
        closeAll();
        err(1, "Could not fstat");
    }

    Triple tr;
    int readBytes = 0;
    int offset = 0;
    while((readBytes = read(fds[1], &tr, sizeof(tr))) > 0)
    {
        if(tr.offset + tr.length > st.st_size)
        {
            closeAll();
            err(1, "Out of bounds");
        }

        if(lseek(fds[0], tr.offset, SEEK_SET) < 0)
        {
            closeAll();
            err(1, "Could not lseek");
        }

        char buff[4096];

        if(read(fds[0], buff, tr.length) != tr.length)
        {
            closeAll();
            err(1, "Could not read");
        }

        buff[tr.length] = '\0';

        if(startsWithCapital(buff) == true)
        {
            if(write(fds[2], buff, strlen(buff)) != (ssize_t)strlen(buff))
            {
                closeAll();
                err(1, "Could not write");
            }

            Triple newTr;
            newTr.length = tr.length;
            newTr.offset = offset;
            newTr.padding = 0;
            offset += newTr.length;

            if(write(fds[3], &newTr, sizeof(newTr)) != sizeof(newTr))
            {
                closeAll();
                err(1, "Could not write");
            }
        }
    }

    if(readBytes < 0)
    {
        closeAll();
        err(1, "Err reading");
    }

    closeAll();

        return 0;
}
