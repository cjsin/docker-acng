FROM debian:10

LABEL author="cjsin"

ENV WORK="/acng" \
    USER="apt-cacher-ng" \
    DEBIAN_FRONTEND="noninteractive" \
    PACKAGES="apt-cacher-ng ca-certificates wget" \
    PORT=3143

RUN  apt-get update \
     && apt-get install --no-install-recommends -y ${PACKAGES} \
     && rm -rf /var/lib/apt/lists/*

WORKDIR ${WORK}/

COPY * ${WORK}/

RUN  bash -n *.sh \
     && chmod a+rx *sh \
     && ln -sf ${WORK}/entrypoint.sh /entrypoint \
     && ln -sf ${WORK}/healthz.sh /healthz \
     && ln -sf ${WORK}/backends /etc/apt-cacher-ng/backends \
     && cp -f acng.conf /etc/apt-cacher-ng/ \
     && mkdir -p log cache backends \
     && touch  log/apt-cacher.log log/apt-cacher.err \
     && chown -R apt-cacher-ng:root ${WORK}/log ${WORK}/cache \
     && chmod -R 0755 ${WORK}/ \
     && chown -R apt-cacher-ng /etc/apt-cacher-ng

EXPOSE      $PORT/tcp

HEALTHCHECK --interval=60s --timeout=5s --retries=3 CMD /healthz $PORT

USER        ${USER}:${USER}

ENTRYPOINT  [ "/entrypoint" ]

CMD         [ ]
