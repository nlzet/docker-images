FROM nlzet/php74-cli

USER root
RUN \
    apt-get update && \
    apt-get install -y supervisor && \
    systemctl enable ssh && service ssh start && \
    apt-get -y clean && apt-get -y purge && rm -rf /var/lib/apt/lists/* && rm -Rf /tmp/pear

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
CMD ["supervisord", "-c", "/etc/supervisor/supervisord.conf"]
