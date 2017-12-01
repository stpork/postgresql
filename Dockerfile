FROM centos:centos7

# PostgreSQL image for OpenShift.
# Volumes:
#  * /var/lib/psql/data   - Database cluster for PostgreSQL
# Environment:
#  * $POSTGRESQL_USER     - Database user name
#  * $POSTGRESQL_PASSWORD - User's password
#  * $POSTGRESQL_DATABASE - Name of the database to create
#  * $POSTGRESQL_ADMIN_PASSWORD (Optional) - Password for the 'postgres'
#                           PostgreSQL administrative account

ENV POSTGRESQL_VERSION=9.5 \
    POSTGRESQL_PREV_VERSION=9.4 \
    HOME=/var/lib/pgsql \
    PGUSER=postgres

ENV SUMMARY="PostgreSQL is an advanced Object-Relational database management system" \
    DESCRIPTION="PostgreSQL is an advanced Object-Relational database management system (DBMS). \
The image contains the client and server programs that you'll need to \
create, run, maintain and access a PostgreSQL DBMS server."

LABEL summary=$SUMMARY \
      description="$DESCRIPTION" \
      io.k8s.description="$DESCRIPTION" \
      io.k8s.display-name="PostgreSQL 9.5" \
      io.openshift.expose-services="5432:postgresql" \
      io.openshift.tags="database,postgresql,postgresql95,rh-postgresql95" \
      name="centos/postgresql-95-centos7" \
      com.redhat.component="rh-postgresql95-docker" \
      version="9.5" \
      release="1" \
      maintainer="SoftwareCollections.org <sclorg@redhat.com>"

EXPOSE 5432

COPY root/usr/libexec/fix-permissions /usr/libexec/fix-permissions

# This image must forever use UID 26 for postgres user so our volumes are
# safe in the future. This should *never* change, the last test is there
# to make sure of that.
RUN yum install -y centos-release-scl-rh \
&& INSTALL_PKGS="rsync tar gettext bind-utils nss_wrapper rh-postgresql95 rh-postgresql95-postgresql-contrib rh-postgresql94-postgresql-server" \
&& yum -y --setopt=tsflags=nodocs install $INSTALL_PKGS \
&& rpm -V $INSTALL_PKGS \
&& yum clean all \
&& localedef -f UTF-8 -i en_US en_US.UTF-8 \
&& test "$(id postgres)" = "uid=26(postgres) gid=26(postgres) groups=26(postgres)" \
&& mkdir -p $HOME/data \
&& /usr/libexec/fix-permissions $HOME \
&& /usr/libexec/fix-permissions /var/run/postgresql

# Get prefix path and path to scripts rather than hard-code them in scripts
ENV CONTAINER_SCRIPTS_PATH=/usr/share/container-scripts/postgresql \
    ENABLED_COLLECTIONS=rh-postgresql95

COPY root /

# When bash is started non-interactively, to run a shell script, for example it
# looks for this variable and source the content of this file. This will enable
# the SCL for all scripts without need to do 'scl enable'.
ENV BASH_ENV=${CONTAINER_SCRIPTS_PATH}/scl_enable \
    ENV=${CONTAINER_SCRIPTS_PATH}/scl_enable \
    PROMPT_COMMAND=". ${CONTAINER_SCRIPTS_PATH}/scl_enable"

VOLUME ["$HOME/data"]

USER 26

ENTRYPOINT ["container-entrypoint"]
CMD ["run-postgresql"]
