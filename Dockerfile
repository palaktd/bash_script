# Taking the coder base image which should contain all coder relevant info
FROM ghcr.io/coder/coder:v2.16.1
USER root
RUN apk add --no-cache --update \
    python3 \
    python3-dev \
    py3-pip \
    build-base \
    bash \
    unzip \
    aws-cli \
    curl \
    gcc \
    musl-dev \
    libffi-dev \
    openssl-dev \
    cargo \
    make \
    ca-certificates \
    less \
    ncurses-terminfo-base \
    krb5-libs \
    libgcc \
    libintl \
    libssl3 \
    libstdc++ \
    tzdata \
    userspace-rcu \
    zlib \
    icu-libs

RUN chown -R coder:coder /home/coder \
 && mkdir /etc/coder.d

COPY coder.env gcpconfig.json config.yaml /etc/coder.d/
COPY cdwcon.png mbos.png /home/coder/.cache/coder/site/bin/

# Install powershell
RUN apk -X https://dl-cdn.alpinelinux.org/alpine/edge/main add --no-cache lttng-ust \
&& curl -L https://github.com/PowerShell/PowerShell/releases/download/v7.4.5/powershell-7.4.5-linux-musl-x64.tar.gz -o /tmp/powershell.tar.gz \
&& mkdir -p /opt/microsoft/powershell/7 \
&& tar zxf /tmp/powershell.tar.gz -C /opt/microsoft/powershell/7 \
&& chmod +x /opt/microsoft/powershell/7/pwsh \
&& ln -s /opt/microsoft/powershell/7/pwsh /usr/bin/pwsh \
&& chown -R coder:coder /home/coder

USER coder

# Install Google Cloud CLI and Azure CLI
RUN curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-linux-x86_64.tar.gz \
    && tar -xf google-cloud-cli-linux-x86_64.tar.gz \
    && ./google-cloud-sdk/install.sh \
    && rm -rf google-cloud-cli-linux-x86_64.tar.gz \
    && python3 -m venv /home/coder/venv \
    && . /home/coder/venv/bin/activate \
    && pip install --upgrade pip \
    && pip install setuptools azure-cli

COPY cdwcon.png mbos.png /home/coder/.cache/coder/site/bin/

# Set environment variable for GCP and Azure
ENV PATH="/home/coder/google-cloud-sdk/bin:/home/coder/venv/bin:$PATH"

# Ensure successfull login of Azure account
RUN . /etc/coder.d/coder.env && \
 az login --service-principal -u "$ARM_CLIENT_ID" -p "$ARM_CLIENT_SECRET" --tenant "$ARM_TENANT_ID"

# Install Azure Powershell on Linux
RUN pwsh -Command "Install-Module -Name Az -Repository PSGallery -Force"

# Ensure successful login of Azure Powershell
RUN . /etc/coder.d/coder.env && \
 pwsh -command "Connect-AzAccount -ServicePrincipal -Credential (New-Object PSCredential ('$ARM_CLIENT_ID', (ConvertTo-SecureString '$ARM_CLIENT_SECRET' -AsPlainText -Force))) -Tenant '$ARM_TENANT_ID'"
