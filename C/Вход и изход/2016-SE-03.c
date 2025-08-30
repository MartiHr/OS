#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdlib.h>
#include <stdint.h>
#include <err.h>
#include <errno.h>

#define CHUNK_SIZE 10000000  // ~40 MB (10^7 uint32_t)
#define MAX_CHUNKS 100

// Compare function for qsort
int compare_uint32(const void *a, const void *b) {
    uint32_t x = *(uint32_t*)a;
    uint32_t y = *(uint32_t*)b;
    if (x < y) return -1;
    if (x > y) return 1;
    return 0;
}

typedef struct {
    int fd;
    uint32_t current;
    int finished;
} TempFile;

void read_next(TempFile *tf) {
    ssize_t r = read(tf->fd, &tf->current, sizeof(uint32_t));
    if (r == -1) err(1, "read");
    if (r == 0) tf->finished = 1;
    else if (r != sizeof(uint32_t)) errx(1, "partial read");
}

int main(int argc, char **argv) {
    if (argc != 2)
        errx(1, "Usage: %s <binary_file>", argv[0]);

    const char *filename = argv[1];
    int fd = open(filename, O_RDONLY);
    if (fd == -1) err(1, "open input file");

    char temp_names[MAX_CHUNKS][20];
    int chunk_count = 0;

    while (1) {
        uint32_t *buffer = malloc(CHUNK_SIZE * sizeof(uint32_t));
        if (!buffer) err(1, "malloc");

        ssize_t total_read = 0;
        while (total_read < CHUNK_SIZE * sizeof(uint32_t)) {
            ssize_t r = read(fd, (char*)buffer + total_read,
                             CHUNK_SIZE * sizeof(uint32_t) - total_read);
            if (r == -1) err(1, "read");
            if (r == 0) break;
            total_read += r;
        }
        size_t read_count = total_read / sizeof(uint32_t);
        if (read_count == 0) {
            free(buffer);
            break;
        }

        qsort(buffer, read_count, sizeof(uint32_t), compare_uint32);

        // Write temp file
        snprintf(temp_names[chunk_count], 20, "chunk_%d.tmp", chunk_count);
        int temp_fd = open(temp_names[chunk_count], O_WRONLY | O_CREAT | O_TRUNC, 0600);
        if (temp_fd == -1) err(1, "open temp");

        ssize_t total_written = 0;
        while (total_written < read_count * sizeof(uint32_t)) {
            ssize_t w = write(temp_fd, (char*)buffer + total_written,
                              read_count * sizeof(uint32_t) - total_written);
            if (w == -1) err(1, "write temp");
            total_written += w;
        }

        close(temp_fd);
        free(buffer);
        chunk_count++;
    }

    close(fd);

    // Мерджване на temp файловете
    TempFile temp_files[MAX_CHUNKS];
    for (int i = 0; i < chunk_count; i++) {
        temp_files[i].fd = open(temp_names[i], O_RDONLY);
        if (temp_files[i].fd == -1) err(1, "open temp for merge");
        temp_files[i].finished = 0;
        read_next(&temp_files[i]);
    }

    int out_fd = open(filename, O_WRONLY | O_TRUNC);
    if (out_fd == -1) err(1, "open output");

    while (1) {
        int min_index = -1;
        for (int i = 0; i < chunk_count; i++) {
            if (!temp_files[i].finished) {
                if (min_index == -1 || temp_files[i].current < temp_files[min_index].current)
                    min_index = i;
            }
        }
        if (min_index == -1) break;

        ssize_t w = write(out_fd, &temp_files[min_index].current, sizeof(uint32_t));
        if (w == -1) err(1, "write output");
        if (w != sizeof(uint32_t)) errx(1, "partial write output");

        read_next(&temp_files[min_index]);
    }

    for (int i = 0; i < chunk_count; i++) {
        close(temp_files[i].fd);
        unlink(temp_names[i]);
    }
    close(out_fd);

    return 0;
}


// had it been with memory restriction :
#include <stdlib.h>
#include <stdint.h>
#include <sys/stat.h>
#include <err.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <stdio.h>
#include <string.h>

#define CHUNK_SIZE (1024 * 1024) // 1 MB buffer (fits 512K uint16_t numbers)

int comp(const void *a, const void *b) {
    uint16_t x = *(const uint16_t*)a;
    uint16_t y = *(const uint16_t*)b;
    return (x > y) - (x < y);
}

// Create sorted chunk files
int create_chunks(const char *input, char ***temp_files) {
    int fd = open(input, O_RDONLY);
    if (fd < 0) err(1, "open input");

    uint16_t *buffer = malloc(CHUNK_SIZE);
    if (!buffer) err(1, "malloc");

    int chunk_count = 0;
    *temp_files = NULL;

    ssize_t r;
    while ((r = read(fd, buffer, CHUNK_SIZE)) > 0) {
        if (r % sizeof(uint16_t) != 0) {
            errx(3, "Input file is not aligned to uint16_t");
        }

        int n = r / sizeof(uint16_t);
        qsort(buffer, n, sizeof(uint16_t), comp);

        // temp file name
        char *fname;
        asprintf(&fname, "chunk_%d.tmp", chunk_count);
        int out = open(fname, O_WRONLY | O_CREAT | O_TRUNC, 0644);
        if (out < 0) err(1, "open chunk");

        if (write(out, buffer, r) != r) err(1, "write chunk");
        close(out);

        *temp_files = realloc(*temp_files, sizeof(char*) * (chunk_count + 1));
        (*temp_files)[chunk_count] = fname;

        chunk_count++;
    }

    if (r < 0) err(1, "read input");

    free(buffer);
    close(fd);
    return chunk_count;
}

// Merge chunks using k-way merge
void merge_chunks(char **temp_files, int chunk_count, const char *output) {
    int *fds = malloc(sizeof(int) * chunk_count);
    uint16_t *heads = malloc(sizeof(uint16_t) * chunk_count);
    int *valid = malloc(sizeof(int) * chunk_count);

    for (int i = 0; i < chunk_count; i++) {
        fds[i] = open(temp_files[i], O_RDONLY);
        if (fds[i] < 0) err(1, "open temp file");

        if (read(fds[i], &heads[i], sizeof(uint16_t)) == sizeof(uint16_t)) {
            valid[i] = 1;
        } else {
            valid[i] = 0;
        }
    }

    int out = open(output, O_WRONLY | O_CREAT | O_TRUNC, 0644);
    if (out < 0) err(1, "open output");

    while (1) {
        int min_idx = -1;
        uint16_t min_val = 0;

        // find smallest among heads
        for (int i = 0; i < chunk_count; i++) {
            if (valid[i]) {
                if (min_idx == -1 || heads[i] < min_val) {
                    min_idx = i;
                    min_val = heads[i];
                }
            }
        }

        if (min_idx == -1) break; // all exhausted

        // write min value
        if (write(out, &min_val, sizeof(min_val)) != sizeof(min_val)) {
            err(1, "write output");
        }

        // refill that chunk
        if (read(fds[min_idx], &heads[min_idx], sizeof(uint16_t)) != sizeof(uint16_t)) {
            valid[min_idx] = 0; // exhausted
        }
    }

    close(out);
    for (int i = 0; i < chunk_count; i++) {
        close(fds[i]);
        unlink(temp_files[i]); // delete temp file
        free(temp_files[i]);
    }

    free(fds);
    free(heads);
    free(valid);
}

int main(int argc, char *argv[]) {
    if (argc != 3) {
        errx(1, "Usage: %s input output", argv[0]);
    }

    char **temp_files;
    int chunk_count = create_chunks(argv[1], &temp_files);
    merge_chunks(temp_files, chunk_count, argv[2]);
    free(temp_files);

    return 0;
}
