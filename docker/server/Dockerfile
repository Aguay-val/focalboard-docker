FROM ubuntu
RUN apt-get update && \
    apt-get install wget unzip -y
RUN mkdir /app
WORKDIR /app
RUN wget https://github.com/mattermost/focalboard/releases/download/v0.6.1/focalboard-server-linux-amd64.tar.gz
RUN tar -xvf focalboard-server-linux-amd64.tar.gz
WORKDIR /app/focalboard/

EXPOSE 8000
ENTRYPOINT [ "/app/focalboard/bin/focalboard-server" ]
