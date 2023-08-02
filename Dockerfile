FROM ubuntu:22.04
LABEL name="ubuntu22-minimal" \
      version="22.04" \
      summary="Provides the latest custom image based on Ubuntu 22.04" \
      tags="minimal ubuntu ubuntu2204"
RUN DEBIAN_FRONTEND=noninteractive \
    echo 'APT::Install-Suggests "0";' >> /etc/apt/apt.conf.d/00-docker && \
    echo 'APT::Install-Recommends "0";' >> /etc/apt/apt.conf.d/00-docker && \
    echo 'APT::Get::Assume-Yes "true";' >> /etc/apt/apt.conf.d/00-docker && \
    apt-get update && apt-get -y upgrade && apt-get install -y -qq --no-install-recommends \
    apt-transport-https \
    apt-utils \
    ca-certificates \
    curl \
    aspnetcore-runtime-7.0 \
    gettext-base \
    gzip \
    jq \
    git \
    iputils-ping \
    lsb-release \
    netcat \
    unzip \
    wget \
    zip \
    && curl -LsS https://aka.ms/InstallAzureCLIDeb | bash && \
    apt-get autoremove -y && \
    apt-get purge -y --auto-remove && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    adduser default --uid 1001 --gid 0 \
      --home /azp --shell /sbin/nologin \
      --disabled-password --gecos "App User"
USER default
WORKDIR /azp
ENV PATH="$HOME/bin:$PATH"
COPY --chown=default:root start-job.sh .
RUN curl -LsS \
    $(curl -skL https://github.com/microsoft/azure-pipelines-agent/releases/latest | grep vsts-agent-linux-x64 | tr " " "\n" | grep href | awk -F"=" '{print $2}' | tr -d '"') \
    -o - | tar -xz && \
    chmod 755 start-job.sh run-docker.sh && \
    az extension add --name containerapp && \
    az extension add --name azure-devops && \
    az extension add --name k8s-extension && \
    az extension add --name ml
CMD [ "/azp/start-job.sh" ]
