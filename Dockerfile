FROM lscr.io/linuxserver/beets:latest

# Install jq for JSON parsing
RUN apk add --no-cache jq

# Set default work directory (can be overridden by compose)
WORKDIR /scripts

# Default command is bash, overridden in compose
ENTRYPOINT ["bash"]
