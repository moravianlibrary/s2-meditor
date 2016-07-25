FROM openshift/base-centos7

MAINTAINER Martin Rumanek <martin@rumanek.cz>
ENV TOMCAT_MAJOR=8 \
    TOMCAT_VERSION=8.5.4 \
    CATALINA_HOME=/usr/local/tomcat \
    JAVA_TOOL_OPTIONS=-Dfile.encoding=UTF8 \
    JDBC_DRIVER_DOWNLOAD_URL=https://jdbc.postgresql.org/download/postgresql-9.4-1201.jdbc41.jar \
    MAVEN_VERSION=3.3.9 \
    DJATOKA_HOME=$HOME/.meditor/djatoka \
    LD_LIBRARY_PATH=$HOME/.meditor/djatoka/lib/Linux-x86-64 \
    KAKADU_HOME=$HOME/.meditor/djatoka/bin/Linux-x86-64 \
    KAKADU_LIBRARY_PATH=-DLD_LIBRARY_PATH=$HOME/.meditor/djatoka/lib/Linux-x86-64


ENV JAVA_OPTS -Dfile.encoding=UTF8 -Djava.awt.headless=true -Dfile.encoding=UTF8 -XX:MaxPermSize=256m -Xms1024m -Xmx3072m -Dkakadu.home=$KAKADU_HOME -Djava.library.path=$LD_LIBRARY_PATH $KAKADU_LIBRARY_PATH


ENV TOMCAT_TGZ_URL=https://www.apache.org/dist/tomcat/tomcat-$TOMCAT_MAJOR/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz

# Set the labels that are used for Openshift to describe the builder image.
LABEL io.k8s.description="MEditor" \
    io.k8s.display-name="MEditor" \
    io.openshift.expose-services="8080:http" \
    io.openshift.tags="builder,meditor" \
    io.openshift.s2i.scripts-url="image:///usr/libexec/s2i"
    
# exiftool
RUN yum install -y perl-CPAN \
        && wget http://www.sno.phy.queensu.ca/~phil/exiftool/Image-ExifTool-10.20.tar.gz \
        && tar -xzf Image-ExifTool-10.20.tar.gz \
        && cd Image-ExifTool-10.20 \
        && perl Makefile.PL \
        && make install \
        && cd .. \
        && rm -r Image-ExifTool-10.20 \
        && rm Image-ExifTool-10.20.tar.gz


RUN INSTALL_PKGS="tar" && \
    yum install -y --enablerepo=centosplus $INSTALL_PKGS && \
    rpm -V $INSTALL_PKGS && \
    yum clean all -y && \
     (curl -v https://www.apache.org/dist/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz | \
    tar -zx -C /usr/local) && \
    ln -sf /usr/local/apache-maven-$MAVEN_VERSION/bin/mvn /usr/local/bin/mvn

WORKDIR $CATALINA_HOME

RUN set -ex \
	&& for key in \
		05AB33110949707C93A279E3D3EFE6B686867BA6 \
		07E48665A34DCAFAE522E5E6266191C37C037D42 \
		47309207D818FFD8DCD3F83F1931D684307A10A5 \
		541FBE7D8F78B25E055DDEE13C370389288584E7 \
		61B832AC2F1C5A90F0F9B00A1C506407564C17A3 \
		79F7026C690BAA50B92CD8B66A3AD3F4F22C4FED \
		9BA44C2621385CB966EBA586F72C284D731FABEE \
		A27677289986DB50844682F8ACB77FC2E86E29AC \
		A9C5DF4D22E99998D9875A5110C01C5A2F6059E7 \
		DCFD35E0BF8CA7344752DE8B6FB21E8933C60243 \
		F3A04C595DB5B6A5F1ECA43E3B7BBB100D811BBE \
		F7DA48BB64BCB84ECBA7EE6935CD23C10D498E23 \
	; do \
		gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
	done

RUN set -x \
	&& curl -fSL "$TOMCAT_TGZ_URL" -o tomcat.tar.gz \
	&& curl -fSL "$TOMCAT_TGZ_URL.asc" -o tomcat.tar.gz.asc \
	&& gpg --batch --verify tomcat.tar.gz.asc tomcat.tar.gz \
	&& tar -xvf tomcat.tar.gz --strip-components=1 \
	&& rm bin/*.bat \
	&& rm tomcat.tar.gz

RUN curl -sL "$JDBC_DRIVER_DOWNLOAD_URL" -o $CATALINA_HOME/lib/postgresql-9.4-1201.jdbc41.jar

# because openjdk doesn't work https://sourceforge.net/p/djatoka/mailman/djatoka-general/
RUN curl -sL --no-verbose http://ftp-devel.mzk.cz/jre/jdk-7u75-linux-x64.tar.gz -o /tmp/java.tar.gz
RUN mkdir -p /usr/local/java
ENV JAVA_HOME /usr/local/java/jdk1.7.0_75
RUN tar xzf /tmp/java.tar.gz --directory=/usr/local/java
ENV PATH $JAVA_HOME/bin:$PATH

#TLS
RUN keytool -genkey -alias tomcat  -dname "CN=localhost, OU=mzk, S=cz, C=cz" -keyalg RSA -storepass somekey -keypass somekey
ADD rewrite.config $CATALINA_HOME/conf/Catalina/localhost/
ADD server.xml $CATALINA_HOME/conf/

RUN mkdir -p $HOME/.meditor

# want empty properties configuration
RUN touch $HOME/.meditor/configuration.properties
ADD ldap.properties $HOME/.meditor/ldap.properties

# z39.50
ADD indexdata.repo /etc/yum.repos.d/indexdata.repo
RUN rpm --import http://ftp.indexdata.com/pub/yum/centos/7/RPM-GPG-KEY-indexdata
RUN yum -y install libyaz5
RUN yum -y install ImageMagick libtiff-tools 
ADD libyaz4j.so $HOME/lib/libyaz4j.so

COPY  ["run", "assemble", "save-artifacts", "usage", "/usr/libexec/s2i/"]

RUN chown -R 1001:0 $HOME $CATALINA_HOME

RUN chmod -R ug+rwx $HOME $CATALINA_HOME

USER 1001
EXPOSE 8080

CMD ["/usr/libexec/s2i/usage"]

