FROM openjdk:17

RUN mkdir -p /opt/shinyproxy/

RUN curl https://www.shinyproxy.io/downloads/shinyproxy-3.1.0.jar -o /opt/shinyproxy/shinyproxy.jar

COPY shinyproxy/templates /opt/shinyproxy/templates
COPY shinyproxy/application.yml /opt/shinyproxy/application.yml

COPY shinyproxy/admin_users.txt /opt/shinyproxy/admin_users.txt
COPY shinyproxy/regular_users.txt /opt/shinyproxy/regular_users.txt
COPY shinyproxy/users.yml /opt/shinyproxy/users.yml

COPY .env /opt/shinyproxy/.env

WORKDIR /opt/shinyproxy/

RUN curl https://www.bmc.org/themes/custom/bmc_base_theme/assets/favicon/favicon.ico -o /opt/shinyproxy/favicon.ico

COPY shinyproxy/entrypoint.sh /opt/shinyproxy/entrypoint.sh
RUN chmod +x /opt/shinyproxy/entrypoint.sh

CMD ["/opt/shinyproxy/entrypoint.sh"]
