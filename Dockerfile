# MicroQuickJS (MQuickJS) Docker Image
# Lightweight JavaScript engine for embedded systems

FROM ubuntu:24.04 AS builder

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    clang \
    llvm \
    make \
    libc6-dev \
    libclang-rt-18-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

# Copy source files
COPY . .

# Build the project
RUN make clean 2>/dev/null || true && make

# Runtime stage - minimal image
FROM ubuntu:24.04 AS runtime

WORKDIR /app

# Copy built executables from builder
COPY --from=builder /build/mqjs /usr/local/bin/mqjs
COPY --from=builder /build/example /usr/local/bin/mquickjs-example

# Copy test files for verification
COPY --from=builder /build/tests /app/tests

# Set default command to run the REPL
ENTRYPOINT ["mqjs"]
CMD []

# Development stage - includes build tools
FROM ubuntu:24.04 AS development

# Install all development dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    clang \
    llvm \
    llvm-dev \
    make \
    libc6-dev \
    gdb \
    valgrind \
    git \
    lcov \
    sudo \
    libclang-rt-18-dev \
    && rm -rf /var/lib/apt/lists/*

# Coverage stage - optimized for code coverage analysis
FROM ubuntu:24.04 AS coverage

# Install coverage-specific tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    clang \
    llvm \
    lld \
    make \
    libc6-dev \
    libclang-rt-18-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

# Copy source files
COPY . .

# Environment variables for coverage
ENV LLVM_PROFILE_FILE=/workspace/coverage/mqjs-%p.profraw
ENV PATH="/usr/lib/llvm-18/bin:${PATH}"

# Create coverage output directory
RUN mkdir -p /workspace/coverage

# Default command runs coverage
CMD ["make", "coverage"]

WORKDIR /workspace

USER $USERNAME

# Default command for development
CMD ["/bin/bash"]
