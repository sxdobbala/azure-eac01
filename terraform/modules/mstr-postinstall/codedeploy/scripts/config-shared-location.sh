#!/bin/sh

config()
{
  #Check if it is a clustered MSTR instance
  if [ -d "/efs" ]; then
    #check shared directory exist or not, if not, create one
    SharedDirectory=$1
    if [ ! -d "$SharedDirectory" ]; then
      echo "Creating shared directory $SharedDirectory"
      mkdir "$SharedDirectory"
    fi

    Ip=`findmnt -o SOURCE -n /efs`
    MountPoint=$2

    #check mount point exist or not, if not, create one
    if [ ! -d "$MountPoint" ]; then
      echo "Creating mount point $MountPoint"
      mkdir "$MountPoint"
    fi

    #Make sure $MountPoint exists in /etc/fstab
    if ! findmnt -s "$MountPoint"; then
      sh -c "echo '$SharedDirectory $MountPoint none  bind,defaults 0 0 bg' >> /etc/fstab"
    fi

    if  mountpoint -q "$MountPoint"; then
      echo "Mount point has been mounted already."
    else
      echo "Mounting $MountPoint"
      mount $MountPoint
    fi

    mountpoint "$MountPoint"
    chown mstr:mstr $MountPoint
  fi
}

SharedDirectory="/efs/saas_data/inbox"
MountPoint="/opt/mstr/MicroStrategy/IntelligenceServer/Inbox"
config $SharedDirectory $MountPoint

SharedDirectory="/efs/saas_data/WorkingSetDir"
MountPoint="/opt/mstr/MicroStrategy/IntelligenceServer/WorkingSetDir"
config $SharedDirectory $MountPoint

SharedDirectory="/efs/saas_data/SessRcvryDir"
MountPoint="/opt/mstr/MicroStrategy/IntelligenceServer/SessRcvryDir"
config $SharedDirectory $MountPoint

SharedDirectory="/efs/saas_data/local"
MountPoint="/opt/opa/local"
config $SharedDirectory $MountPoint