#!/bin/bash
# Add java prereqs for Jenkins slave

RCLOCAL="/etc/rc.local"
JAVA_VERSION=$1

# Install Java rpm

rpm -Uvh "$JAVA_VERSION" > /dev/null 2>&1

if [ "$?" -eq "0" ]; then
   echo "Java installed successfully....Setting alternatives.."
   alternatives --install /usr/bin/java java /usr/java/latest/bin/java 200000
   alternatives --install /usr/bin/javac javac /usr/java/latest/bin/javac 200000
   alternatives --install /usr/bin/jar jar /usr/java/latest/bin/jar 200000
   echo "updating rc.local..."
   echo "export JAVA_HOME=\"/usr/java/latest\"" >> $RCLOCAL
   if [ "$?" -eq "0" ]; then
      # Add Jenkins user
      echo "Adding Jenkins user...."
      useradd -d /var/lib/jenkins jenkins
      if getent passwd jenkins > /dev/null 2>&1; then
         echo "setting up ssh dir for key"
         su - jenkins -c "mkdir /var/lib/jenkins/.ssh"
      else
         echo "Problem creating Jenkins users"
         exit 3
      fi
   else
      echo "Could not update $RCLOCAL"
      exit 4
else
   echo "Problem installing java..."
   exit 5
fi


