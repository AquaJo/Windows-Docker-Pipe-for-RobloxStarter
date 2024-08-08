# Use node with minimal bookworm that supports recent enough version of GLIBC
FROM node:20-bookworm-slim

# Install necessary native tools
RUN apt-get update && \
    apt-get install -y \
    git \
    wget \
    unzip \
    rsync \
    procps \
    && rm -rf /var/lib/apt/lists/*

# Install git-lfs
RUN wget -q https://github.com/git-lfs/git-lfs/releases/download/v3.5.1/git-lfs-linux-amd64-v3.5.1.tar.gz && \
    tar -xzf git-lfs-linux-amd64-v3.5.1.tar.gz && \
    ./git-lfs-3.5.1/install.sh && \
    rm -rf git-lfs-linux-amd64-v3.5.1.tar.gz git-lfs-3.5.1
RUN git lfs install

# Load and install aftman
RUN wget -q https://github.com/LPGhatguy/aftman/releases/download/v0.3.0/aftman-0.3.0-linux-x86_64.zip && \
    unzip aftman-0.3.0-linux-x86_64.zip && \
    ./aftman self-install && \
    rm aftman-0.3.0-linux-x86_64.zip
RUN ./aftman trust UpliftGames/rojo && ./aftman trust rojo-rbx/tarmac


# Set working directory for project
WORKDIR /app

# Clone latest RobloxStarter from github and set it up
RUN git clone https://github.com/AquaJo/RobloxStarter .

# Install tarmac and rojo -- needed to be trusted before, done that directly after installing aftman in general already
RUN /aftman install

# Install node dependencies
RUN npm install

WORKDIR /WSL

COPY ./WSL_Insert ./
# Make sure entrypoint.sh is executable
RUN chmod +x addSymlinks.sh counter.txt
RUN /WSL/addSymlinks.sh

CMD ["tail", "-f", "/dev/null"]
