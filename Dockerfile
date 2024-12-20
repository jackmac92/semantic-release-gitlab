FROM	node:20

RUN	apt update -y \
	&& apt install -y git jq jo wget curl unzip python3 python3-toml python3-distutils python3-apt build-essential moreutils
RUN	useradd releaser --home /home/releaser \
	&& mkdir /home/releaser \
	&& chown -R releaser:releaser /home/releaser
USER	releaser:releaser
WORKDIR	/home/releaser
RUN	curl -fsSL https://get.pnpm.io/install.sh | env PNPM_VERSION=9.12.2 SHELL="$(which bash)" bash -
ENV	PNPM_HOME	/home/releaser/.local/share/pnpm
ENV	PATH	"${PNPM_HOME}:${PATH}"
ENV	NPM_CONFIG_PREFIX	"/home/releaser/.npm-global"
RUN	mkdir $NPM_CONFIG_PREFIX
RUN	npm install --global semantic-release @semantic-release/exec @semantic-release/git @semantic-release/commit-analyzer @semantic-release/gitlab @semantic-release/npm @semantic-release/release-notes-generator
COPY	scripts	./scripts
COPY	gitGlobalIgnore	gitGlobalIgnore
RUN	git config --global core.excludesfile gitGlobalIgnore
USER	root
RUN	find scripts -type f -exec chmod +x {} \;
USER	releaser:releaser
ENV	PATH	"$PATH:/home/releaser/scripts"
COPY	init.sh	./
USER	root
CMD	["bash","/home/releaser/init.sh"]
