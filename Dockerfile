
# Use Ubuntu 20.04 as the base image (which has Python 3.8)
FROM ubuntu:20.04

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Set timezone
ENV TZ=Etc/UTC

# Install system dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-dev \
    libpq-dev \
    build-essential \
    git \
    libssl-dev \
    libffi-dev \
    tzdata \
    && rm -rf /var/lib/apt/lists/*

# Set up a non-root user
RUN useradd -m -s /bin/bash wagtail

# Set the working directory
WORKDIR /app

# Copy the project files
COPY . /app

# Change ownership of the app directory to the non-root user
RUN chown -R wagtail:wagtail /app

# Switch to the non-root user
USER wagtail

# Add local bin to PATH
ENV PATH="/home/wagtail/.local/bin:${PATH}"

# Upgrade pip and install a specific version of setuptools
RUN python3 -m pip install --user --upgrade pip && \
    python3 -m pip install --user setuptools==58.2.0

# Install pytest and other testing dependencies explicitly
RUN python3 -m pip install --user pytest pytest-django

# Install the project dependencies using pyproject.toml
RUN pip install --user -e .[testing]

# Set environment variable for Django settings
ENV DJANGO_SETTINGS_MODULE=wagtail.test.settings

# Create a shell script to run the specific test
RUN echo '#!/bin/bin/bash' > /app/run_tests.sh && \
    echo 'python3 -m pytest \' >> /app/run_tests.sh && \
    echo '    wagtail/snippets/tests/test_snippets.py \' >> /app/run_tests.sh && \
    echo '    -vv \' >> /app/run_tests.sh && \
    echo '    --tb=long \' >> /app/run_tests.sh && \
    echo '    -rA \' >> /app/run_tests.sh && \
    echo '    -p no:cacheprovider \' >> /app/run_tests.sh && \
    echo '    -o console_output_style=classic \' >> /app/run_tests.sh && \
    echo '    --capture=no' >> /app/run_tests.sh && \
    chmod +x /app/run_tests.sh

# Verify the script exists and is executable
RUN ls -la /app/run_tests.sh && \
    [ -f /app/run_tests.sh ] && \
    [ -x /app/run_tests.sh ] && \
    head -n 10 /app/run_tests.sh

# Run the tests as the default command
CMD ["/bin/bash", "/app/run_tests.sh"]
