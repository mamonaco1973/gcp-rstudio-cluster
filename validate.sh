
#!/bin/bash

NFS_IP=$(gcloud compute instances list \
  --filter="name~'^nfs-gateway'" \
  --format="value(networkInterfaces.accessConfigs[0].natIP)")

echo "NOTE: Linux nfs-gateway public IP address is $NFS_IP"


WIN_IP=$(gcloud compute instances list \
  --filter="name~'^win-ad'" \
  --format="value(networkInterfaces.accessConfigs[0].natIP)")

echo "NOTE: Windows instance public IP address is $WIN_IP"

RSTUDIO_LB_IP=$(gcloud compute addresses describe rstudio-lb-ip --global --format="value(address)")

if [ -z "$RSTUDIO_LB_IP" ]; then
    echo "ERROR: Failed to retrieve the load balancer IP address. Exiting."
    exit 1
fi

URL="http://$RSTUDIO_LB_IP/auth-sign-in"

while true; do
  HTTP_CODE=$(curl -o /dev/null -s -w "%{http_code}" "$URL")
  
  if [ "$HTTP_CODE" -eq 200 ]; then
     echo "NOTE: Load balancer is active. Access RStudio at http://$RSTUDIO_LB_IP"
     exit 0
    break
  else
    echo "WARNING: Waiting for the load balancer to become active."
    sleep 60  
  fi
done
