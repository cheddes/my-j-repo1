FROM ubuntu:14.04
MAINTAINER Siva Chedde "sivakumar.chedde@gmail.com"
ENV REFRESHED_AT 2014-06-01
RUN apt-get update && apt-get install -y wget git curl zip && rm -rf /var/lib/apt/lists/*

##MAVEN INSTALLATION BEGINS HERE
ENV MAVEN_VERSION 3.0.5
RUN curl -sSL http://mirror.bit.edu.cn/apache/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz | tar xzf - -C /usr/share \
&& mv /usr/share/apache-maven-$MAVEN_VERSION /usr/share/maven \
&& ln -s /usr/share/maven/bin/mvn /usr/bin/mvn
ADD settings.xml /usr/share/maven/conf/
ENV MAVEN_HOME /usr/share/maven

#FROM LOCAL JDK ARCHIVE
RUN wget --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/7u79-b15/jdk-7u79-linux-x64.tar.gz
RUN mkdir -p /usr/lib/jvm
RUN tar -zxf jdk-7u79-linux-x64.tar.gz -C /usr/lib/jvm
RUN update-alternatives --install /usr/bin/java java /usr/lib/jvm/jdk1.7.0_79/bin/java 100
RUN update-alternatives --install /usr/bin/javac javac /usr/lib/jvm/jdk1.7.0_79/bin/javac 100
ENV JAVA_HOME /usr/lib/jvm/jdk1.7.0_79

#ADDING JENKINS
ENV JENKINS_HOME /var/jenkins_home

# Jenkins is ran with user `jenkins`, uid = 1000
# If you bind mount a volume from host/vloume from a data container, 
# ensure you use same uid
# 
# 
# boot2docker down
# cd "C:\Program Files\Oracle\VirtualBox"
# VBoxManage sharedfolder add boot2docker-vm --name mydata --hostpath "D:\Workspace"
# boot2docker up
# boot2docker ssh 'sudo mkdir -p /data'
# boot2docker ssh 'sudo mount -t vboxsf -o "defaults,uid=1000,gid=1000,rw" mydata /data'
# TO RUN
# boot2docker ssh
# docker run -d -v /data:/var/jenkins_home --name hcl_dccs_aem_2 -p 8080:8080 cheddes/hcl_dccs_aem_ci:2.0.0
RUN useradd -d "$JENKINS_HOME" -u 1000 -m -s /bin/bash jenkins

# Jenkins home directoy is a volume, so configuration and build history 
# can be persisted and survive image upgrades
VOLUME /var/jenkins_home

# `/usr/share/jenkins/ref/` contains all reference configuration we want 
# to set on a fresh new installation. Use it to bundle additional plugins 
# or config file with your custom jenkins Docker image.
RUN mkdir -p /usr/share/jenkins/ref/init.groovy.d


COPY init.groovy /usr/share/jenkins/ref/init.groovy.d/tcp-slave-agent-port.groovy

ENV JENKINS_VERSION 1.609.1
ENV JENKINS_SHA 698284ad950bd663c783e99bc8045ca1c9f92159

# could use ADD but this one does not check Last-Modified header 
# see https://github.com/docker/docker/issues/8331
RUN curl -fL http://mirrors.jenkins-ci.org/war-stable/$JENKINS_VERSION/jenkins.war -o /usr/share/jenkins/jenkins.war   && echo "$JENKINS_SHA /usr/share/jenkins/jenkins.war" | sha1sum -c -

ENV JENKINS_UC https://updates.jenkins-ci.org
RUN chown -R jenkins "$JENKINS_HOME" /usr/share/jenkins/ref

# for main web interface:
EXPOSE 8080

# will be used by attached slave agents:
EXPOSE 50000

ENV COPY_REFERENCE_FILE_LOG /var/log/copy_reference_file.log
RUN touch $COPY_REFERENCE_FILE_LOG && chown jenkins.jenkins $COPY_REFERENCE_FILE_LOG

USER jenkins

COPY jenkins.sh /usr/local/bin/jenkins.sh
ENTRYPOINT ["/usr/local/bin/jenkins.sh"]
