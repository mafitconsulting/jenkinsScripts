#!/bin/bash
# Add java prereqs for Jenkins slave

set -x

RCLOCAL="/etc/rc.local"
JAVA_VERSION=$1
TYPE=$2
RC=0

if [ "$#" != "2" ]; then
  echo "USAGE: jenkinsPreReqs.sh <JRE RPM> <MASTER|SLAVE>"
  exit 1
fi

prereq() {
   echo "Java installed successfully....Setting alternatives.."
   alternatives --install /usr/bin/java java /usr/java/latest/bin/java 200000
   alternatives --install /usr/bin/javac javac /usr/java/latest/bin/javac 200000
   alternatives --install /usr/bin/jar jar /usr/java/latest/bin/jar 200000
   echo "Updating rc.local..."
   echo "export JAVA_HOME=\"/usr/java/latest\"" >> $RCLOCAL
   if [ "$?" -eq "0" ]; then
      echo "Successully updated rc.local"
      # Add Jenkins user
      echo "Adding Jenkins user...."
      useradd -d /var/lib/jenkins jenkins
      if getent passwd jenkins > /dev/null 2>&1; then
         echo "Successfully created Jenkins user"
         if [ "$TYPE" == "SLAVE" ]; then
            echo "Setting up ssh dir for authorized_keys on slave"
            su - jenkins -c "mkdir /var/lib/jenkins/.ssh"
            su - jenkins -c "touch /var/lib/jenkins/.ssh/authorized_keys"
         fi
      else
         echo "Problem creating Jenkins users"
         exit 3
      fi
   else
      echo "Could not update $RCLOCAL"
      exit 4
   fi
   return $RC
}


installJenkins () {
  echo "Creating Jenkins repo and installing Jenkins Master"
  wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
  rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key
  yum install -y jenkins-2.19.4-1.1
  if [ "$?" -eq "0" ]; then
    echo "Jenkins installed successfully"
    systemctl start jenkins
    if [ "$?" -eq "0" ]; then
        systemctl enable jenkins
        echo "Jenkins service started and enabled"
    else
        echo "Could not started Jenkins server"
        exit 13
    fi
  else
    echo "Jenkins installation failed"
    exit 123
  fi
  return $RC
}
     



# MAIN

CHECKJRE=`java -version 2> /dev/null`
if [ "$?" -eq "0" ]; then
   echo "Java already installed. Performing prereqs"
   prereq
   if [ "$RC" -eq "0" ]; then
     installJenkins
     if [ "$RC" -eq "0" ]; then
         echo "Jenkins installed successfully"
     else
         echo "Jenkins install failed"
     fi
   else
      echo "Jenkins prereqs failed"
   fi
else
  echo "Installing Java.. please wait.."
  rpm -Uvh "$JAVA_VERSION" > /dev/null 2>&1 
  if [ "$?" -eq "0" ]; then
     prereq
     if [ "$RC" -eq "0" ]; then
        installJenkins
        if [ "$RC" -eq "0" ]; then
          echo "Jenkins installed successfully"
        else
          echo "Jenkins install failed"

        fi
     fi
  else
      echo "Jenkins prereqs failed"
  fi
fi

