FROM python:3.10.17-alpine3.22

ENV WORKDIR=/opt/operator/ \
    USER_UID=1001 \
    USER_NAME=mistral-operator

RUN echo 'https://dl-cdn.alpinelinux.org/alpine/v3.20/main/' > /etc/apk/repositories && \
    echo 'https://dl-cdn.alpinelinux.org/alpine/v3.20/community/' >> /etc/apk/repositories



# hadolint ignore=DL3008, DL3009, DL3018
# RUN apk update && \
#     apk add --no-cache \
#       expat=2.4.3-r0

RUN apk update

COPY build/requirements.txt requirements.txt
COPY build/user_setup /usr/local/bin
COPY build/entrypoint /usr/local/bin

RUN pip install --upgrade pip==23.3 && pip install -r requirements.txt

# RUN pip install --upgrade pip==23.3 "setuptools==70.0.0"

COPY src/handler.py ${WORKDIR}
COPY src/mistral_constants.py ${WORKDIR}
COPY src/kubernetes_helper.py ${WORKDIR}
COPY src/rabbitmq_helper.py ${WORKDIR}
COPY src/liveness_probe.sh ${WORKDIR}

RUN chmod 777 /usr/local/bin/user_setup && \
chmod 777 /usr/local/bin/entrypoint && \
chmod -R 777 /opt/operator

RUN /usr/local/bin/user_setup

ENTRYPOINT ["/usr/local/bin/entrypoint"]

CMD ["sh", "-c", "kopf run -n ${WATCH_NAMESPACE} --standalone /opt/operator/handler.py"]

RUN find / -perm /6000 -type f -exec chmod a-s {} \; || true

USER ${USER_UID}
