FROM golang:1.16-alpine AS build

WORKDIR /src
COPY go.* *.go ./
RUN go build -o ./webhook-receiver

FROM alpine

COPY --from=build /src/webhook-receiver /
EXPOSE 8080
ENTRYPOINT [ "/webhook-receiver", "-bind=:8080" ]
