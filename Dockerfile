FROM debian:buster-slim

RUN set -ex && \
# Install all necessary packages.
    apt-get update && \
    apt-get install -y \
            rsync \
            build-essential \
            curl \
            libffi6 \
            libffi-dev \
            libssl-dev \
            python3 \
            python3-dev \
            openssl \
    && \
# Install certbot.
    curl -L 'https://bootstrap.pypa.io/get-pip.py' | python3 && \
    pip3 install -U cffi certbot \
    && \
# Install Gandi DNS plugin
    pip3 install --no-cache-dir certbot-plugin-gandi \
    && \
# Remove everything that is no longer necessary.
    apt-get remove --purge -y \
            build-essential \
            curl \
            libffi-dev \
            libssl-dev \
            python3-dev \
    && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* \
    && \
# Create user 1000
    groupadd --gid 1000 letsencrypt && \
    useradd letsencrypt --uid 1000 --gid 1000 --shell /bin/false &&\
    mkdir /ssl && \
    chown letsencrypt:letsencrypt /ssl \
    && \
# DONE !!!
    echo "Done"
# DONE

# Copy in our scripts and make them executable.
COPY scripts/ /scripts
RUN chmod +x -R /scripts

RUN mkdir /certbot-first-run/
RUN touch /certbot-first-run/.first

# Change the container's start command to launch our entrypoint script.
CMD ["/bin/bash", "/scripts/entrypoint.sh"]
