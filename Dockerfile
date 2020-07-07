# Only works in cluster
FROM python:3.6-slim

ENV PYTHONUNBUFFERED=1

WORKDIR /servo
RUN mkdir adjust.d

# Install required packages
ADD  https://storage.googleapis.com/kubernetes-release/release/v1.16.2/bin/linux/amd64/kubectl /usr/local/bin/

ADD ./requirements.txt /servo/
RUN pip3 install -r requirements.txt

ADD https://raw.githubusercontent.com/opsani/servo-agg/master/adjust \
    https://raw.githubusercontent.com/opsani/servo-agg/master/util.py \
    https://raw.githubusercontent.com/opsani/servo-prom/master/measure \
    https://raw.githubusercontent.com/opsani/servo/master/adjust.py \
    https://raw.githubusercontent.com/opsani/servo/master/measure.py \
    https://raw.githubusercontent.com/opsani/servo/master/servo \
    /servo/

ADD https://raw.githubusercontent.com/opsani/servo-k8s/status-rejected-onfail-destroy/adjust /servo/adjust.d/01-k8s-adjust
ADD ./adjust /servo/adjust.d/02-k8slive-adjust

RUN chmod a+rx /servo/adjust /servo/measure /servo/servo /servo/adjust.d/* /usr/local/bin/kubectl && \
 	chmod a+r /servo/adjust.py /servo/measure.py

ENTRYPOINT [ "python3", "servo" ]
