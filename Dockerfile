# Stage 1: Build static binary
FROM alpine:3.20 as builder

RUN apk add --no-cache gcc musl-dev

COPY log_collector.c .
RUN gcc -static -O2 -o log_collector log_collector.c

# Stage 2: Minimal runtime container
FROM scratch

COPY --from=builder /log_collector /log_collector

# Use a volume to persist logs
VOLUME ["/data"]

CMD ["/log_collector"]
