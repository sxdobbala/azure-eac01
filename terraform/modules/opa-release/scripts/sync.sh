# !/bin/bash
#
# Script to transfer release artifacts from S3 to EC2. Parameters expected:
#   $1 = opa_release_bucket_id
#   $2 = release_id
#   $3 = opa_api_mstr_bucket_id
#
# If opa_etls.jar and oap-mstr-web.war do not exist in the new release package, copy them from current_release folder.
# Update current_release folder with new_release folder.
# If mstr-content folder exists in current release package, update /opt/opa/install/mstr-content folder.
# opa_api_mstr.zip will be copied from opa_api_mstr_bucket_id and not from release package.

INSTALL_DIR="/opt/opa/install"
API_MSTR_ZIP="opa_api_mstr.zip"

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

SharedDirectory="/efs/saas_data/local"
MountPoint="/opt/opa/local"
config $SharedDirectory $MountPoint

sudo su - mstr

mkdir -p /opt/opa/local/current_release
mkdir -p /opt/opa/local/next_release
cd /opt/opa/local

aws s3 sync --no-progress $1/$2/ ./next_release
aws s3 cp $3/$API_MSTR_ZIP ./next_release/$API_MSTR_ZIP

touch next_release/current-is-$2
for f in current_release/opa_etls.jar current_release/oap-mstr-web.war current_release/opa-rep-loaders.zip; do 
if [ ! -f "next_release/`basename $f`" ]; then 
cp -r $f ./next_release/`basename $f`; 
fi; 
done 

rm -rf current_release
mv next_release current_release 
cd current_release
mkdir -p $INSTALL_DIR/mstr-content

if [ -d "mstr-content" ]; then 
cp -r mstr-content $INSTALL_DIR; 
fi 

if [ -f "/opt/mstr/MicroStrategy/Migration/migration_file.yaml" ]; then 
cp -n /opt/mstr/MicroStrategy/Migration/migration_file.yaml $INSTALL_DIR/mstr-content/migration_file.yaml; 
fi

chgrp -R mstr $INSTALL_DIR/mstr-content/

if [  -d "$INSTALL_DIR/opa-rep-loaders" ]; then 
rm -rf $INSTALL_DIR/opa-rep-loaders; 
fi 

mkdir -p $INSTALL_DIR/opa-rep-loaders

unzip opa-rep-loaders.zip -d $INSTALL_DIR/opa-rep-loaders

if [  -d "$INSTALL_DIR/mstr-infra" ]; then 
rm -rf $INSTALL_DIR/mstr-infra; 
fi

mkdir -p $INSTALL_DIR/mstr-infra
unzip $API_MSTR_ZIP -d $INSTALL_DIR/mstr-infra

# etl is not in use now. Comment it out temporarily

# if [  -d "$INSTALL_DIR/etl" ]; then 
# rm -rf $INSTALL_DIR/etl; 
# fi 
# mkdir -p $INSTALL_DIR/etl
# unzip opa_etls.jar -d $INSTALL_DIR/etl