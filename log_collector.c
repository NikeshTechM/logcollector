#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/statvfs.h>
#include <time.h>

void log_memory_usage(FILE *f) {
    FILE *meminfo = fopen("/proc/meminfo", "r");
    if (!meminfo) {
        fprintf(f, "Failed to read /proc/meminfo\n");
        return;
    }

    char line[256];
    long memTotal = 0, memFree = 0;
    while (fgets(line, sizeof(line), meminfo)) {
        if (sscanf(line, "MemTotal: %ld kB", &memTotal) == 1) continue;
        if (sscanf(line, "MemFree: %ld kB", &memFree) == 1) continue;
    }
    fclose(meminfo);

    fprintf(f, "Memory - Total: %ld MB, Free: %ld MB\n", memTotal / 1024, memFree / 1024);
}

void log_disk_usage(FILE *f) {
    struct statvfs stat;
    if (statvfs("/data", &stat) != 0) {
        fprintf(f, "Failed to get disk usage\n");
        return;
    }

    unsigned long total = (stat.f_blocks * stat.f_frsize) / (1024 * 1024);
    unsigned long free  = (stat.f_bfree * stat.f_frsize) / (1024 * 1024);
    fprintf(f, "Disk  - Total: %lu MB, Free: %lu MB\n", total, free);
}

int main() {
    while (1) {
        FILE *f = fopen("/data/syslog.txt", "a");
        if (!f) {
            perror("Failed to open log file");
            return 1;
        }

        time_t now = time(NULL);
        fprintf(f, "\n[%s]\n", ctime(&now));
        log_memory_usage(f);
        log_disk_usage(f);
        fclose(f);

        sleep(1);  // ✅ changed to 1 second-2607-108
    }
    return 0;
}
