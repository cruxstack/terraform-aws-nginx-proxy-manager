FROM mcr.microsoft.com/devcontainers/base:jammy

RUN apt update && apt install -y \
    vim

# install aws
RUN SYSTEM_ARCH=$(uname -m) \
    && curl "https://awscli.amazonaws.com/awscli-exe-linux-${SYSTEM_ARCH}-2.13.33.zip" -o "awscliv2.zip" \
    && unzip -qq awscliv2.zip \
    && aws/install \
    && aws --version \
    && rm -rf aws

# install terraform
ENV TERRAFORM_VERSION=1.6.6
ENV TF_PLUGIN_CACHE_DIR=$HOME/.terraform.d/plugin-cache
RUN mkdir -p $TF_PLUGIN_CACHE_DIR
RUN SYSTEM_ARCH=$(dpkg --print-architecture) \
    && curl -OL https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${SYSTEM_ARCH}.zip \
    && unzip terraform_${TERRAFORM_VERSION}_linux_${SYSTEM_ARCH}.zip \
    && mv terraform /usr/local/bin/ \
    && terraform version \
    && rm terraform_${TERRAFORM_VERSION}_linux_${SYSTEM_ARCH}.zip

# install tflint
RUN curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash

# install pip
RUN apt-get update
RUN apt-get install -y \
    python3-pip \
    shellcheck

# install python packages
RUN python3 -m pip install \
    boto3 \
    black

# verify installs
RUN terraform --version

