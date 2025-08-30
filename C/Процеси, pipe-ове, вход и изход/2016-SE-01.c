#include "unistd.h"
#include "err.h"
#include  "fcntl.h"
#include "string.h"
#include "sys/wait.h"

int pfd[2] = {-1, -1};

void close_all(void)
{
    if(pfd[0] >= 0)
    {
        close(pfd[0]);
    }

    if(pfd[1] >= 0)
    {
        close(pfd[1]);
    }
}

int main(int argc, char* argv[])
{
    if(argc != 2)
    {
        errx(1, "Invalid num of args");
    }

    const char* file1 = argv[1];


    if(pipe(pfd) < 0)
    {
        err(1, "Could not pipe");
    }

    int catPid = fork();

    if(catPid < 0)
    {
        err(1, "Could not fork");
    }

    if(catPid == 0)
    {
        close(pfd[0]);
        if(dup2(pfd[1], 1) < 0)
        {
            close_all();
            err(1, "Dup failed");
        }
        close(pfd[1]);

        execlp("cat", "cat", file1, (char*)NULL);
        err(1, "Did not exec");
    }

    close(pfd[1]);

    int status;
    if(wait(&status) < 0)
    {
        close_all();
        err(1, "Cat did not exec");
    }

    if(!WIFEXITED(status) || WEXITSTATUS(status) != 0)
    {
        close_all();
        err(1, "Child failed");
    }

    if(dup2(pfd[0], 0) < 0)
    {
        close_all();
        err(1, "dup2 failed");
    }

    close(pfd[0]);

    execlp("sort", "sort", (char*) NULL);
    err(1, "Sort did not exec");

    close_all();

}
