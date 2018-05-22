=======================
Cleaning the Deployment
=======================

Removing Helm Charts
====================

To delete an installed helm chart, use the following command:

.. code-block:: shell

  helm delete ${RELEASE_NAME} --purge

This will delete all Kubernetes resources generated when the chart was
instantiated. However for OpenStack charts, by default, this will not delete
the database and database users that were created when the chart was installed.
All OpenStack projects can be configured such that upon deletion, their database
will also be removed. To delete the database when the chart is deleted the
database drop job must be enabled before installing the chart. There are two
ways to enable the job, set the job_db_drop value to true in the chart's
values.yaml file, or override the value using the helm install command as
follows:

.. code-block:: shell

  helm install ${RELEASE_NAME} --set manifests.job_db_drop=true


Environment tear-down
=====================

To tear-down, the development environment charts should be removed first from
the 'openstack' namespace and then the 'ceph' namespace using the commands from
the `Removing Helm Charts` section. Additonally charts should be removed from
the 'nfs' and 'libvirt' namespaces if deploying with NFS backing or bare metal
development support. You can run the following commands to loop through and
delete the charts, then stop the kubelet systemd unit and remove all the
containers before removing the directories used on the host by pods.

.. code-block:: shell

  for NS in openstack ceph nfs libvirt; do
     helm ls --namespace $NS --short | xargs -r -L1 -P2 helm delete --purge
  done

  sudo systemctl stop kubelet
  sudo systemctl disable kubelet

  sudo docker ps -aq | xargs -r -L1 -P16 sudo docker rm -f

  sudo rm -rf /var/lib/openstack-helm/*

  # NOTE(portdirect): These directories are used by nova and libvirt
  sudo rm -rf /var/lib/nova/*
  sudo rm -rf /var/lib/libvirt/*
  sudo rm -rf /etc/libvirt/qemu/*

  # NOTE(portdirect): Clean up mounts left behind by kubernetes pods
  sudo findmnt --raw | awk '/^\/var\/lib\/kubelet\/pods/ { print $1 }' | xargs -r -L1 -P16 sudo umount -f -l


These commands will restore the environment back to a clean Kubernetes
deployment, that can either be manually removed or over-written by
restarting the deployment process. It is recommended to restart the host before
doing so to ensure any residual state, eg. Network interfaces are removed.
