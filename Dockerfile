FROM python:3.9-alpine

RUN mkdir /app && mkdir /data
WORKDIR /app

RUN apk update && \
    apk add bash && \
    apk add jq && \
    pip3 install --no-cache yq pint

ADD kuberes .
RUN chmod u+x kuberes

ENTRYPOINT ["/app/kuberes"]
