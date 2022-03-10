FROM ubuntu:18.04

RUN apt update && \
    apt install -y git wget sudo && \
    apt install libatomic1 && \
    mkdir -p /home/workspace/.openvscode-server/extensions && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /home/

ARG RELEASE_TAG="openvscode-server-v1.64.2"
ARG RELEASE_ORG="gitpod-io"
ARG OPENVSCODE_SERVER_ROOT="/home/.openvscode-server"

# Downloading the latest VSC Server release and extracting the release archive
# Rename `openvscode-server` cli tool to `code` for convenience
RUN if [ -z "${RELEASE_TAG}" ]; then \
        echo "The RELEASE_TAG build arg must be set." >&2 && \
        exit 1; \
    fi && \
    arch=$(uname -m) && \
    if [ "${arch}" = "x86_64" ]; then \
        arch="x64"; \
    elif [ "${arch}" = "aarch64" ]; then \
        arch="arm64"; \
    elif [ "${arch}" = "armv7l" ]; then \
        arch="armhf"; \
    fi && \
    wget  https://ghproxy.com/https://github.com/${RELEASE_ORG}/openvscode-server/releases/download/${RELEASE_TAG}/${RELEASE_TAG}-linux-${arch}.tar.gz && \
    tar -xzf ${RELEASE_TAG}-linux-${arch}.tar.gz && \
    mv -f ${RELEASE_TAG}-linux-${arch} ${OPENVSCODE_SERVER_ROOT} && \
    cp ${OPENVSCODE_SERVER_ROOT}/bin/remote-cli/openvscode-server ${OPENVSCODE_SERVER_ROOT}/bin/remote-cli/code && \
    rm -f ${RELEASE_TAG}-linux-${arch}.tar.gz


ENV JAVA_HOME=/usr/local/java
ENV CLASSPATH=:/usr/local/java/lib/
ENV GO_HOME=/usr/local/go
ENV PATH=$PATH:/usr/local/go/bin:/usr/local/java/bin:/usr/local/maven/.maven/bin

RUN wget https://buildpack.oss-cn-shanghai.aliyuncs.com/jdk/cedar-14/openjdk1.8.0_201.tar.gz && \
    mkdir -p /usr/local/java && \
    tar -xzf openjdk1.8.0_201.tar.gz -C /usr/local/java && \
    rm -rf openjdk1.8.0_201.tar.gz
    
RUN wget https://buildpack.oss-cn-shanghai.aliyuncs.com/java/maven/maven-3.3.9.tar.gz && \
    mkdir -p /usr/local/maven && \
    tar -xzf maven-3.3.9.tar.gz -C /usr/local/maven/ && \
    rm -rf maven-3.3.9.tar.gz

RUN wget https://buildpack.oss-cn-shanghai.aliyuncs.com/go/go1.11.13.linux-amd64.tar.gz && \
    tar -xzf go1.11.13.linux-amd64.tar.gz -C /usr/local/ && \
    rm -rf go1.11.13.linux-amd64.tar.gz

RUN wget https://buildpack.oss-cn-shanghai.aliyuncs.com/nodejs/node/release/linux-x64/node-v12.18.3-linux-x64.tar.gz && \
    tar -xzf node-v12.18.3-linux-x64.tar.gz -C /usr/local/ && \
    ln -s /usr/local/node-v12.18.3-linux-x64/bin/node /usr/local/bin/ && \
    ln -s /usr/local/node-v12.18.3-linux-x64/bin/npm /usr/local/bin/ && \
    rm -rf node-v12.18.3-linux-x64.tar.gz

RUN wget  https://rainbond-pkg.oss-cn-shanghai.aliyuncs.com/open_vscould/gitlab.gitlab-workflow-3.40.2.tar &&     tar xf gitlab.gitlab-workflow-3.40.2.tar -C /home/workspace/.openvscode-server/extensions/

RUN  wget https://rainbond-pkg.oss-cn-shanghai.aliyuncs.com/open_vscould/ms-ceintl.vscode-language-pack-zh-hans-1.64.7.tar && \
     tar xf ms-ceintl.vscode-language-pack-zh-hans-1.64.7.tar -C /home/workspace/.openvscode-server/extensions/

RUN  wget https://buildpack.oss-cn-shanghai.aliyuncs.com/python/cedar-14/runtimes/python-3.8.3.tar.gz && \
     tar -xzf python-3.8.3.tar.gz -C /usr/local/ && \
     ln -s /usr/local/bin/python /usr/local/python3.8

ARG USERNAME=openvscode-server
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Creating the user and usergroup
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USERNAME -m -s /bin/bash $USERNAME \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

RUN chmod g+rw /home && \
    mkdir -p /home/workspace && \
    chown -R $USERNAME:$USERNAME /home/workspace && \
    chown -R $USERNAME:$USERNAME ${OPENVSCODE_SERVER_ROOT}

COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

USER $USERNAME

WORKDIR /home/workspace/
VOLUME /home/workspace/

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    HOME=/home/workspace \
    EDITOR=code \
    VISUAL=code \
    GIT_EDITOR="code --wait" \
    OPENVSCODE_SERVER_ROOT=${OPENVSCODE_SERVER_ROOT} \
    PATH="${OPENVSCODE_SERVER_ROOT}/bin/remote-cli:${PATH}"

# Default exposed port if none is specified
EXPOSE 3000


# ENTRYPOINT [ "/bin/sh", "-c", "exec ${OPENVSCODE_SERVER_ROOT}/bin/openvscode-server --host 0.0.0.0 --without-connection-token \"${@}\"", "--" ]
ENTRYPOINT ["docker-entrypoint.sh"]



