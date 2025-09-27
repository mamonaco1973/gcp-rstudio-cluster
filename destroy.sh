
#!/bin/bash

cd 02-servers

terraform init
terraform destroy -auto-approve

cd ..

cd 01-directory

terraform init
terraform destroy -auto-approve

cd ..

