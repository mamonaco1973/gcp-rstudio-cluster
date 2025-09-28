
#!/bin/bash

rstudio_image=$(gcloud compute images list \
  --filter="name~'^rstudio-image' AND family=rstudio-images" \
  --sort-by="~creationTimestamp" \
  --limit=1 \
  --format="value(name)")

if [[ -z "$rstudio_image" ]]; then
  echo "ERROR: No latest image found for 'rstudio-image' in family 'rstudio-images'."
  exit 1
fi

cd 04-cluster

terraform init
terraform destroy -var="rstudio_image_name=$rstudio_image" \
    -auto-approve

cd ..

#-------------------------------------------------------------------------------
# STEP 4: DELETE PACKER-BUILT IMAGES (GAMES & DESKTOP PREFIX)
#-------------------------------------------------------------------------------

echo "NOTE: Fetching images starting with 'rstudio' to delete..."

# List all custom images that match known prefixes
image_list=$(gcloud compute images list \
  --format="value(name)" \
  --filter="name~'^(rstudio)'")  # Regex match for names starting with 'rstudio'

# Check if any were found
if [ -z "$image_list" ]; then
  echo "NOTE: No images found starting with 'rstudio'. Nothing to delete."
else
  echo "NOTE: Deleting images..."
  for image in $image_list; do
    echo "NOTE: Deleting image: $image"
    gcloud compute images delete "$image" --quiet || echo "WARNING: Failed to delete image: $image"  # Continue even if deletion fails
  done
fi

cd 02-servers

terraform init
terraform destroy -auto-approve

cd ..

cd 01-directory

terraform init
terraform destroy -auto-approve

cd ..

