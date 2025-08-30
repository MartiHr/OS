#include <stdlib.h>
#include <sys/wait.h>
#include <err.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>

// cut -d ':' -f7 /etc/passwd | sort | uniq -c | sort -n

int pfd[3][2];

void close_all(void)
{
    int oldErrno = errno;

    for(int i = 0; i < 3; i++)
    {
        for(int j = 0; j < 2; j++)
        {
            if(pfd[i][j] >= 0)
            {
                close(pfd[i][j]);
            }
        }
    }

    errno = oldErrno;
}

void wait_child(void)
{
    int status;
    if(wait(&status) < 0)
    {
        close_all();
        err(1, "Could not wait for child");
    }

    if(!WIFEXITED(status) || WEXITSTATUS(status) != 0)
    {
        close_all();
        err(1, "Child failed");
    }
}

int fork_safe(void)
{
    int pid = fork();

    if(pid < 0)
    {
        close_all();
        err(1, "Could not fork");
    }

    return pid;
}

int main(void)
{
    // --- CUT ---
    if(pipe(pfd[0]) < 0)
    {
        close_all();
        err(1, "Could not pipe");
    }

    int cut_pid = fork_safe();

    if(cut_pid == 0)
    {
        close(pfd[0][0]); // child doesn't read
        if(dup2(pfd[0][1], 1) < 0)
        {
            close_all();
            err(1, "Could not dup");
        }
        close(pfd[0][1]); // close after dup2

        execlp("cut", "cut", "-d:", "-f7", "/etc/passwd", (char*)NULL);
        err(1, "Could not exec");
        exit(1);
    }

    close(pfd[0][1]); // parent closes write so next stage sees EOF
    wait_child();

    // --- SORT ---
    if(pipe(pfd[1]) < 0)
    {
        close_all();
        err(1, "Could not pipe");
    }

    int sort_pid = fork_safe();

    if(sort_pid == 0)
    {
        close(pfd[1][0]); // child doesn't read from its own write end
        if(dup2(pfd[0][0], 0) < 0 || dup2(pfd[1][1], 1) < 0) // original had: if(dup2(pfd[0][0],0)||dup2...) BAD
        {
            close_all();
            err(1, "Could not dup");
        }

        close(pfd[0][0]); // close after dup2
        close(pfd[1][1]); // close after dup2

        execlp("sort", "sort", (char*)NULL);
        err(1, "Could not exec");
        exit(1);
    }

    close(pfd[0][0]); // parent no longer needs read end
    close(pfd[1][1]); // parent closes write end so next stage sees EOF
    wait_child();

    // --- UNIQ ---
    if(pipe(pfd[2]) < 0)
    {
        close_all();
        err(1, "Could not pipe");
    }

    int uniq_pid = fork_safe();

    if(uniq_pid == 0)
    {
        close(pfd[2][0]); // child doesn't read
        if(dup2(pfd[1][0], 0) < 0 || dup2(pfd[2][1], 1) < 0)
        {
            close_all();
            err(1, "Could not dup");
        }

        close(pfd[1][0]); // close after dup2
        close(pfd[2][1]); // close after dup2

        execlp("uniq", "uniq", "-c", (char*) NULL);
        err(1, "Could not exec");
        exit(1);
    }

    close(pfd[1][0]); // parent closes read end
    close(pfd[2][1]); // parent closes write end so final sort sees EOF
    wait_child();

    // --- FINAL SORT ---
    if(dup2(pfd[2][0], 0) < 0) // parent reads from last pipe
    {
        close_all();
        err(1, "Could not dup");
    }

    close(pfd[2][0]); // close after dup2
    execlp("sort", "sort", "-n", (char*) NULL);
    err(1, "Could not exec");

    close_all();
    return 0;
}

// OR
// after all forks and closing unused pipe ends
while (wait(NULL) > 0);  // wait for all children

