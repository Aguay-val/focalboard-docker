FROM ubuntu
RUN apt-get update && \
    apt-get install wget unzip jq -y
RUN mkdir /app
WORKDIR /app
RUN wget https://github.com/mattermost/focalboard/releases/download/v0.6.1/focalboard-server-linux-amd64.tar.gz
RUN tar -xvf focalboard-server-linux-amd64.tar.gz
WORKDIR /app/focalboard/
RUN mv config.json config.json.save
COPY entrypoint.sh /app/entrypoint.sh
EXPOSE 8000
ENTRYPOINT [ "/app/entrypoint.sh"]
CMD [ "/app/focalboard/bin/focalboard-server" ]