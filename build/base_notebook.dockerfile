FROM registry.access.redhat.com/ubi8/ubi-minimal:8.1
WORKDIR /home
RUN microdnf install python3 \
    && ln -s /usr/bin/python3 /usr/bin/python \
    && ln -s /usr/bin/pip3 /usr/bin/pip \
    && pip install --upgrade pip \
    && pip install --no-cache-dir notebook \
    && microdnf clean all
EXPOSE 8888
ENTRYPOINT ["jupyter", "notebook", "--ip=0.0.0.0", "--no-browser", "--allow-root", "--NotebookApp.token=''"]
