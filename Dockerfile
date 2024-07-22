FROM node:20

RUN apt update -y && apt install -y git jq jo wget curl unzip python3 python3-distutils python3-apt build-essential moreutils
RUN curl -fsSL https://get.pnpm.io/install.sh | sh -
RUN npm install --global semantic-release @semantic-release/exec @semantic-release/git @semantic-release/gitlab @semantic-release/commit-analyzer @semantic-release/npm @semantic-release/release-notes-generator
RUN useradd releaser --home /home/releaser && mkdir /home/releaser && chown -R releaser:releaser /home/releaser
USER releaser:releaser
WORKDIR /home/releaser
RUN python -m ensurepip --upgrade
RUN python3 -m pip install toml

COPY scripts ./scripts
COPY gitGlobalIgnore gitGlobalIgnore
RUN git config --global core.excludesfile gitGlobalIgnore

USER root
RUN find scripts -type f -exec chmod +x {} \;
USER releaser:releaser
ENV PATH="$PATH:/home/releaser/scripts"
COPY init.sh ./

CMD bash /home/releaser/init.sh
