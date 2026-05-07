FROM eclipse-temurin:21.0.10_7-jre-ubi9-minimal

ARG UID=1001
ARG JAR_FILE=tmp/application.jar

RUN microdnf update -y \
    && microdnf reinstall tzdata -y \
    && microdnf clean all

RUN adduser -u ${UID} avwebservice

ENV HOME=/avwebservice

WORKDIR ${HOME}

RUN chown ${UID}:0 . \
    && chmod 0775 .

VOLUME ["/avwebservice"]

WORKDIR /application

RUN chown ${UID}:0 . \
    && chmod 0775 .

COPY --chown=${UID}:0 --chmod=0775 ${JAR_FILE} application.jar

USER ${UID}

ENV LOG4J_FORMAT_MSG_NO_LOOKUPS=true
ENV JAVA_OPTS=""

EXPOSE 8080

ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS -XX:+UseParallelGC -XX:MaxRAMPercentage=90.0 -jar /application/application.jar \
  \"--server.port=${SERVER_PORT:-8080}\" \
  \"--server.tomcat.threads.max=${TOMCAT_THREADS_MAX:-200}\" \
  \"--server.tomcat.accept-count=${TOMCAT_ACCEPT_COUNT:-100}\" \
  \"--server.tomcat.max-connections=${TOMCAT_MAX_CONNECTIONS:-10000}\" \
  \"--management.endpoint.health.probes.enabled=true\" \
  \"--management.health.livenessState.enabled=true\" \
  \"--management.health.readinessState.enabled=true\" \
  \"--spring.datasource.url=${DBURL:-jdbc:postgresql://localhost:54321/edit}\" \
  \"--spring.datasource.username=${DBUSR:-ddluser}\" \
  \"--spring.datasource.password=${DBPWD:-ddluser}\" \
  \"--spring.datasource.driver-class-name=${DB_DRIVER:-org.postgresql.Driver}\" \
  \"--logging.level.ch.ehi.av.webservice=${LOG_LEVEL_AVWS:-DEBUG}\" \
  \"--logging.level.org.springframework=${LOG_LEVEL_SPRING:-INFO}\" \
  \"--logging.level.org.springframework.jdbc.core.JdbcTemplate=${LOG_LEVEL_JDBC_TEMPLATE:-DEBUG}\" \
  \"--avws.dbschema=${DBSCHEMA:-stage}\" \
  \"--avws.tmpdir=${TMPDIR:-/tmp}\" \
  \"--avws.cadastreAuthorityUrl=${CADASTRE_AUTHORITY_URL:-https://agi.so.ch}\" \
  \"--avws.webAppUrl=${WEB_APP_URL:-https://geo.so.ch/map/?oereb_egrid=}\" \
  \"--avws.canton=${CANTON:-SO}\" \
  \"--avws.subUnitOfLandRegisterDesignation=${SUB_UNIT_OF_LAND_REGISTER_DESIGNATION:-GB-Gemeinde}\" \
  \"--avws.planForMainPage=${PLAN_FOR_MAIN_PAGE:-https://geodienste.ch/db/av_situationsplan_0/deu?SERVICE=WMS&VERSION=1.3.0&REQUEST=GetMap&FORMAT=image%2Fpng&TRANSPARENT=true&LAYERS=daten&STYLES=&SRS=EPSG%3A2056&CRS=EPSG%3A2056&TILED=false&MAP_RESOLUTION=100&DPI=96&OPACITIES=255&t=675&WIDTH=1920&HEIGHT=710&BBOX=2607051.2375,1228517.0374999999,2608067.2375,1228892.7458333333}\" \
  \"--avws.planForLandDescription=${PLAN_FOR_LAND_DESCRIPTION:-https://geodienste.ch/db/av_situationsplan_0/deu?SERVICE=WMS&VERSION=1.3.0&REQUEST=GetMap&FORMAT=image%2Fpng&TRANSPARENT=true&LAYERS=daten&STYLES=&SRS=EPSG%3A2056&CRS=EPSG%3A2056&TILED=false&MAP_RESOLUTION=100&DPI=96&OPACITIES=255&t=675&WIDTH=1920&HEIGHT=710&BBOX=2607051.2375,1228517.0374999999,2608067.2375,1228892.7458333333}\" \
  \"--avws.planForProjectedObjects=${PLAN_FOR_PROJECTED_OBJECTS:-https://geodienste.ch/db/av_situationsplan_0/deu?SERVICE=WMS&VERSION=1.3.0&REQUEST=GetMap&FORMAT=image%2Fpng&TRANSPARENT=true&LAYERS=daten&STYLES=&SRS=EPSG%3A2056&CRS=EPSG%3A2056&TILED=false&MAP_RESOLUTION=100&DPI=96&OPACITIES=255&t=675&WIDTH=1920&HEIGHT=710&BBOX=2607051.2375,1228517.0374999999,2608067.2375,1228892.7458333333}\""]