FROM runatlantis/atlantis:latest

# Install additional tools if needed
RUN apk add --no-cache \
    curl \
    git \
    openssh-client

# Copy any custom configuration if needed
# COPY atlantis.yaml /etc/atlantis/

# Set working directory
WORKDIR /atlantis

# Expose port
EXPOSE 4141

# The base image already has the correct entrypoint
# ENTRYPOINT ["atlantis", "server"]
