#!/bin/bash
# Add java prereqs for Jenkins slave

RCLOCAL="/etc/rc.local"
JAVA_VERSION=$1
TYPE=$2

if [ "$#" != "2" ]; then
  echo "USAGE: jenkinsPreReqs.sh <JRE RPM> <MASTER|SLAVE>
  exit 1
fi

# Install Java rpm

echo "Installing Java.. please wait.."
rpm -Uvh "$JAVA_VERSION" > /dev/null 2>&1

if [ "$?" -eq "0" ]; then
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
         if [ "$TYPE" -eq "SLAVE" ]; then
            echo "Setting up ssh dir for authorized_keys on slave""
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
else
   echo "Problem installing java..."
   exit 5
fi


