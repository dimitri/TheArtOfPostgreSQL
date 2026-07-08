FROM golang:1.23-alpine AS builder

WORKDIR /build
COPY src/query-ui/ .
RUN go mod download
RUN CGO_ENABLED=0 GOOS=linux go build -o query-ui .

FROM scratch
COPY --from=builder /build/query-ui /
EXPOSE 8042
CMD ["/query-ui", "-port", "8042", "-db", "postgresql://taop:taop@postgres:5432/taop", "-queries", "/queries", "-toc", "/toc.txt", "-params", "/query-params.json", "-starter-kit", "/starter-kit"]
