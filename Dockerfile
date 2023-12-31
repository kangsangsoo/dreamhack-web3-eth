# FROM gcr.io/paradigmxyz/ctf/base:latest
# FROM python:3.10-slim
FROM python:3.9.13

ENV FLAG=DH{fake_flag}

COPY requirements.txt /root

RUN python3 -m pip install -r /root/requirements.txt 

RUN true && \
    apt-get update && \
    apt-get install -y curl git socat bsdmainutils build-essential && \
    true

RUN true \
    && curl -L https://foundry.paradigm.xyz | bash \
    && bash -c "source /root/.bashrc && foundryup" \
    && chmod 755 -R /root \
    && true


COPY chall.py /home/ctf/chall.py

COPY contracts /tmp/contracts/

RUN true \
    && cd /tmp \
    && /root/.foundry/bin/forge build --out /home/ctf/compiled \
    && true


EXPOSE 10089

WORKDIR /home/ctf/
CMD ["python3", "/home/ctf/chall.py"]