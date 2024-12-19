FROM debian:bookworm-slim

WORKDIR /actions-runner

ARG RUNNER_VERSION="2.321.0"
ARG FILENAME="actions-runner-linux-arm64-${RUNNER_VERSION}.tar.gz"

RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl tar jq git zip unzip 

# Install AWS CLI
RUN curl https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip -o ./awscliv2.zip \
  && unzip -q ./awscliv2.zip \
  && ./aws/install

# Install github runner agent
RUN curl -O -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/${FILENAME}

RUN echo "62cc5735d63057d8d07441507c3d6974e90c1854bdb33e9c8b26c0da086336e1  actions-runner-linux-arm64-2.321.0.tar.gz" | shasum -a 256 -c

RUN tar xzf ./${FILENAME} && bin/installdependencies.sh

COPY ./start.sh .
RUN chmod +x ./start.sh

ENV RUNNER_ALLOW_RUNASROOT=true

CMD ["./start.sh"]