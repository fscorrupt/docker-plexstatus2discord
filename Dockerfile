FROM mcr.microsoft.com/powershell:preview-alpine-3.15
LABEL maintainer=fscorrupt
LABEL org.opencontainers.image.source https://github.com/fscorrupt/docker-plexstatus2discord

COPY *.ps1 .

CMD [ "pwsh","./PlexStatus.ps1" ]
