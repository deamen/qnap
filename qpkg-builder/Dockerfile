FROM alpine:3.18.3 as builder
LABEL maintainer="deamen@gmail.com"

ENV PACKAGER="Song Tang <deamen@gmail.com>" \
    USERNAME="abuild" \
    TRANSMISSION_VERSION="3.00" 

RUN apk update && apk --no-cache add \
    build-base git bash curl wget openssl rsync

RUN adduser -S -g abuild $USERNAME
RUN echo "$USERNAME:$USERNAME" | chpasswd
RUN echo "$USERNAME     ALL=(ALL) ALL" >/etc/sudoers
RUN echo 'PACKAGER="$PACKAGER"' >/etc/abuild.conf

RUN addgroup $USERNAME abuild

RUN mkdir -p /var/cache/distfiles
RUN chmod a+w /var/cache/distfiles
RUN chgrp abuild /var/cache/distfiles
RUN chmod g+w /var/cache/distfiles

RUN chmod 777 /home/${USERNAME}

USER root
WORKDIR /home/${USERNAME}

RUN git clone https://github.com/qnap-dev/QDK.git
RUN cd QDK \
    && sed -i 's/apt-get update/echo "Do nothing in Alpine"/g' InstallToUbuntu.sh \
    && sed -i '/apt-get/d' InstallToUbuntu.sh
RUN cd QDK && ./InstallToUbuntu.sh install

WORKDIR /SRC

CMD ["/usr/share/QDK/bin/qbuild"]
