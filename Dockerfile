# Started from here:
# https://medium.com/@jamiekt/vscode-devcontainer-with-zsh-oh-my-zsh-and-agnoster-theme-8adf884ad9f6
# https://github.com/jamiekt/devcontainer1

ARG PYTHON_VERSION=3.8
ARG VARIANT=bookworm
ARG JUPYTER_MODE=ignore
FROM mcr.microsoft.com/vscode/devcontainers/python:${PYTHON_VERSION}-${VARIANT} AS jupyter_ignore

# FROM mcr.microsoft.com/devcontainers/base:bookworm
# Simple Debian container with Git installed.
# Has zsh, oh-my-zsh.
# see https://github.com/devcontainers/images/tree/main/src/base-debian

ARG USERNAME=vscode
ENV HOME /home/${USERNAME}
WORKDIR ${HOME}

# Used to persist bash history as per https://code.visualstudio.com/remote/advancedcontainers/persist-bash-history
RUN SNIPPET="export PROMPT_COMMAND='history -a' && export HISTFILE=/commandhistory/.bash_history" \
    && mkdir /commandhistory \
    && touch /commandhistory/.bash_history \
    && chown -R $USERNAME /commandhistory \
    && echo "$SNIPPET" >> "/home/$USERNAME/.bashrc"

## Install apts (e.g. dircolors, bat, tmux)
RUN apt-get update && \    
    apt-get upgrade --yes --no-install-recommends && \    
    apt install -y coreutils \
    bat \
    tmux \
    tree \
    # required for git clone of private repos using https
    openssh-client \
    # required for linux container under windows
    dos2unix \
    # python3 \
    && apt-get clean

ARG GITHUB_TOKEN
# required for git clone
ARG TERM=xterm-256color

RUN git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm && \
    ~/.tmux/plugins/tpm/scripts/install_plugins.sh

# we install inside the devcontainer and so nhctl

# let zsh be the default shell
ENV SHELL=/usr/bin/zsh

RUN pip install --upgrade pip

FROM jupyter_ignore as jupyter_install
ONBUILD COPY install_jupyter.sh .
ONBUILD RUN chmod +x ./install_jupyter.sh && ./install_jupyter.sh

FROM jupyter_${JUPYTER_MODE}

# To quick test the container locally, run:
# docker build --build-arg GITHUB_TOKEN=${GITHUB_TOKEN} --build-arg GEMFURY_USER=${GEMFURY_USER} --build-arg GEMFURY_TOKEN=${GEMFURY_TOKEN} -t {{cookiecutter.project_slug}}_dev .devcontainer/.