
#!/bin/bash

NFS_IP=$(gcloud compute instances list \
  --filter="name~'^nfs-gateway'" \
  --format="value(networkInterfaces.accessConfigs[0].natIP)")

echo "NOTE: Linux nfs-gateway public IP address is $NFS_IP"


WIN_IP=$(gcloud compute instances list \
  --filter="name~'^win-ad'" \
  --format="value(networkInterfaces.accessConfigs[0].natIP)")

echo "NOTE: Windows instance public IP address is $WIN_IP"
