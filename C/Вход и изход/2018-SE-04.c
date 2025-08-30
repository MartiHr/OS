#include <stdlib.h>
#include <stdint.h>
#include <sys/stat.h>
#include <err.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>

int fds[2] = { -1, -1 };

void close_all(void)
{
    int oldErrno = errno;

    for(int i = 0; i < 2; i++)
    {
        if(fds[i] >= 0)
        {
            close(fds[i]);
        }
    }

    errno = oldErrno;
}

int open_safe_read(const char* str)
{
    int fd = open(str, O_RDONLY);

    if(fd < 0)
    {
        close_all();
        err(1, "Could not open %s", str);
    }

    return fd;
}

int open_safe_write(const char* str)
{
    int fd = open(str, O_WRONLY | O_CREAT | O_TRUNC, 0644);

    if(fd < 0)
    {
        close_all();
        err(1, "Could not open for writing %s", str);
    }

    return fd;
}

int comp(const void* a, const void* b)
{
    uint16_t first = *(const uint16_t*)a;
    uint16_t second = *(const uint16_t*)b;

    if(first < second)
    {
        return -1;
    }
    else if(first > second)
    {
        return 1;
    }
    else
    {
        return 0;
    }

}


int main(int argc, char* argv[])
{
    if(argc != 3)
    {
        errx(1, "Wrong number of arguments");
    }

    const char* inputFile = argv[1];
    const char* outputFile = argv[2];

    fds[0] = open_safe_read(inputFile);
    fds[1] = open_safe_write(outputFile);

    struct stat st;
    if(fstat(fds[0], &st) < 0)
    {
        close_all();
        err(1, "Could not fstat");
    }

    if(st.st_size % sizeof(uint16_t) != 0)
    {
        errx(3, "File %s does not contain uint16_t numbers only", inputFile);
    }

    int numbersCount = st.st_size / sizeof(uint16_t);
    uint16_t* numbers = malloc(numbersCount * sizeof(uint16_t));

    int index = 0;
    uint16_t number;
    int bytesRead = 0;

    while((bytesRead = read(fds[0], &number, sizeof(number))) > 0)
    {
        numbers[index++] = number;
    }


    if(bytesRead < 0)
    {
        close_all();
        err(1, "Error while reading");
    }


    qsort(numbers, numbersCount, sizeof(uint16_t), comp);

    for(int i = 0; i < numbersCount; i++)
    {
        int curr = numbers[i];

        if(write(fds[1], &curr, sizeof(curr)) < 0)
        {
            close_all();
            err(1, "Could not write to %s", outputFile);
        }
    }

    free(numbers);
    close_all();

    return 0;
}
