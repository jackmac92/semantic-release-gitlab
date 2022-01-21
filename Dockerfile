FROM node:16

RUN apt update -y && apt install -y git jq jo wget curl unzip python3-distutils python3-apt build-essential moreutils

RUN npm install --global semantic-release @semantic-release/exec @semantic-release/git @semantic-release/gitlab @semantic-release/commit-analyzer @semantic-release/release-notes-generator
RUN useradd releaser --home /home/releaser && mkdir /home/releaser && chown -R releaser:releaser /home/releaser
USER releaser:releaser
WORKDIR /home/releaser
RUN wget https://bootstrap.pypa.io/get-pip.py
RUN python3 get-pip.py
RUN python3 -m pip install toml


COPY scripts ./scripts
USER root
RUN find scripts -type f -exec chmod +x {} \;
USER releaser:releaser
ENV PATH="$PATH:/home/releaser/scripts"
COPY init.sh ./

CMD bash /home/releaser/init.sh