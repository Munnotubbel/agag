FROM rust:1.81 as builder
WORKDIR /usr/src/backente
COPY . .
RUN cargo build --release

FROM debian:buster-slim
COPY --from=builder /usr/src/backente/target/release/backente /usr/local/bin/backente
EXPOSE 8080
CMD ["backente"]