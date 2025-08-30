#include <sys/wait.h>
#include <unistd.h>
#include <err.h>
#include <fcntl.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

struct myfile {
    uint64_t id;
    uint8_t length;
    char str[256];   // allow up to 255 characters + safety
};

void wait_child(void) {
    int status;
    if (wait(&status) < 0) {
        err(1, "wait failed");
    }
    if (!WIFEXITED(status) || WEXITSTATUS(status)) {
        err(1, "Child failed");
    }
}

int main(int argc, char* argv[]) {
    if (argc < 2 || argc > 21) {
        errx(1, "There should be at least 1 and maximum 20 args");
    }

    int outFd = open("resultFile", O_RDWR | O_CREAT | O_TRUNC, 0644);
    if (outFd < 0) {
        err(5, "Could not open file");
    }

    for (int i = 1; i < argc; i++) {
        int fd = open(argv[i], O_RDONLY);
        if (fd < 0) err(1, "Could not open file");

        uint64_t headerId;
        if (read(fd, &headerId, sizeof(headerId)) != sizeof(headerId)) {
            close(fd);
            err(1, "Wrong format");
        }

        if (headerId != 133742) {
            close(fd);
            errx(1, "Wrong header id");
        }

        uint8_t roleLength;
        if (read(fd, &roleLength, sizeof(roleLength)) != sizeof(roleLength)) {
            close(fd);
            err(1, "Wrong format");
        }
        if (roleLength > 63) {
            close(fd);
            errx(1, "Role name too long");
        }

        char roleName[63];
        if (read(fd, roleName, roleLength) != roleLength) {
            close(fd);
            err(1, "Wrong format");
        }

        struct myfile r;
        ssize_t n;
        char delimiter = '?';
        char secondDel = ':';

        while ((n = read(fd, &r, sizeof(r))) > 0) {
            if (n != sizeof(r)) {
                close(fd);
                errx(1, "Wrong record size");
            }

            if (r.length > 255) { // validate replica length
                close(fd);
                errx(1, "Line too long");
            }

            if (write(outFd, &r.id, sizeof(r.id)) != sizeof(r.id) ||
                write(outFd, &delimiter, sizeof(delimiter)) != sizeof(delimiter) ||
                write(outFd, roleName, roleLength) != roleLength ||
                write(outFd, &secondDel, sizeof(secondDel)) != sizeof(secondDel) ||
                write(outFd, r.str, r.length) != r.length) {
                close(fd);
                err(1, "Write error");
            }
        }
        if (n < 0) {
            close(fd);
            err(1, "Reading error");
        }
        close(fd);
    }

    close(outFd); // flush before using in sort

    int pfd[2];
    if (pipe(pfd) < 0) {
        err(1, "Could not create pipe");
    }

    pid_t sort_pid = fork();
    if (sort_pid < 0) err(1, "Fork failed");

    if (sort_pid == 0) { // sort child
        close(pfd[0]);
        if (dup2(pfd[1], 1) < 0) err(1, "dup2 failed");
        close(pfd[1]);
        execlp("sort", "sort", "-n", "-r", "resultFile", (char*)NULL);
        err(1, "Exec sort failed");
    }

    pid_t cut_pid = fork();
    if (cut_pid < 0) err(1, "Fork failed");

    if (cut_pid == 0) { // cut child
        close(pfd[1]);
        if (dup2(pfd[0], 0) < 0) err(1, "dup2 failed");
        close(pfd[0]);
        execlp("cut", "cut", "-d", "?", "-f", "2-", (char*)NULL);
        err(1, "Exec cut failed");
    }

    close(pfd[0]);
    close(pfd[1]);

    wait_child();
    wait_child();

    unlink("resultFile"); // remove temp file

    return 0;
}
