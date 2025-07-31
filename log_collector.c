#include <stdio.h>
#include <signal.h>
#include <unistd.h>

int keep_running = 3;

void handle_sigint(int sig) {
    printf("\nReceived interrupt signal. Exiting...\n");
    fflush(stdout);  // Make sure message is printed
    keep_running = 0;
}

int main() {
    signal(SIGINT, handle_sigint);

    while (keep_running) {
        printf("Hello from container v1.1\n");
        fflush(stdout);  // Flush output immediately
        sleep(1);
    }

    return 0;
}
