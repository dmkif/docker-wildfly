FROM @@ARCH@@/debian:latest
MAINTAINER Daniel Mulzer <daniel.mulzer@fau.de>
ADD qemu-user-static/bin/qemu-@@ARCH_2@@-static /usr/bin/qemu-@@ARCH_2@@-static

# Install packages necessary to run JBoss Wildfly and GnuCobol
USER root
RUN apt update &&  \
    apt-get -y install curl xmlstarlet libsaxon-java augeas-tools bsdtar tar openjdk-8-jdk-headless libncurses5-dev libgmp-dev && \
    apt-get -y autoremove && \
    apt-get -y clean && \
    rm -rf /var/lib/apt/lists/*

# Set the working directory to jboss' user home directory
WORKDIR /tmp/

#download and install berkley-db in right version
RUN apt-get update && \
    apt-get -y install autoconf build-essential && \
    curl -sLk https://download.oracle.com/berkeley-db/db-4.8.30.NC.tar.gz | tar xz && \
    cd db-4.8.30.NC/build_unix && \
    ../dist/configure --enable-cxx --prefix=/usr && make install && make clean && \
    cd /tmp/ && \
    rm -rf * && \
    apt-get -y --purge autoremove autoconf build-essential && \
    apt-get -y clean && \
    rm -rf /var/lib/apt/lists/*


# download and install open-cobol for depencies (libcob >= 4.0)
RUN apt-get update && \
    apt-get -y install autoconf build-essential && \
    curl -sLk https://sourceforge.net/projects/open-cobol/files/gnu-cobol/3.0/gnucobol-3.0-rc1.tar.gz | tar xz && \
    cd gnucobol-3.0-rc1 && ./configure --prefix=/usr --info-dir=/usr/share/info && make && make install && ldconfig && cd /tmp/ && rm -rf * && \
    apt-get -y --purge autoremove autoconf build-essential && \
    apt-get -y clean && \
    rm -rf /var/lib/apt/lists/*

# Create a user and group used to launch processes
# The user ID 1000 is the default for the first "regular" user on Fedora/RHEL,
# so there is a high chance that this ID will be equal to the current user
# making it easier to use volumes (no permission issues)
RUN groupadd -r jboss -g 1000 && useradd -u 1000 -r -g jboss -m -d /opt/jboss -s /sbin/nologin -c "JBoss user" jboss && \
    chmod 755 /opt/jboss

# Set the working directory to jboss' user home directory
WORKDIR /opt/jboss

# Specify the user which should be used to execute all commands below
USER root

ENV WILDFLY_VERSION 12.0.0.Final
ENV WILDFLY_SHA1 b2039cc4979c7e50a0b6ee0e5153d13d537d492f
ENV JBOSS_HOME /opt/jboss/wildfly



# Add the WildFly distribution to /opt, and make wildfly the owner of the extracted tar content
# Make sure the distribution is available from a well-known place
RUN cd $HOME \
    && curl -O https://download.jboss.org/wildfly/$WILDFLY_VERSION/wildfly-$WILDFLY_VERSION.tar.gz \
    && sha1sum wildfly-$WILDFLY_VERSION.tar.gz | grep $WILDFLY_SHA1 \
    && tar xf wildfly-$WILDFLY_VERSION.tar.gz \
    && mv $HOME/wildfly-$WILDFLY_VERSION $JBOSS_HOME \
    && rm wildfly-$WILDFLY_VERSION.tar.gz \
    && chown -R jboss:0 ${JBOSS_HOME} \
    && chmod -R g+rw ${JBOSS_HOME}

# Ensure signals are forwarded to the JVM process correctly for graceful shutdown
ENV LAUNCH_JBOSS_IN_BACKGROUND true

USER jboss

# Set the JAVA_HOME variable to make it clear where Java is located
ENV JAVA_HOME $(dirname $(dirname $(readlink -f $(which javac))))

EXPOSE 8080 

CMD ["/opt/jboss/wildfly/bin/standalone.sh", "-b", "0.0.0.0", "-bmanagement", "0.0.0.0"]
