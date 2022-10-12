RG="daprized-albums-app"
ACA_ENV="ignite-albums-demo"

# Use this to set a default RG for subsequent commands 
az configure --defaults group=$RG

# Deploy RG and all of the necessary backing resources for this demo using Azure Bicep 
az group create --name daprized-albums-app --location centralus 
az deployment group create -g daprized-albums-app --template-file ./deploy/bicep/infrastructure.bicep 

# Deploy redis + redis component YAML
az containerapp create --yaml redis-capp.yaml -n local-redis -g $RG
az containerapp logs show -n local-redis -g $RG

# Deploy redis + create command
az containerapp create -n local-redis \
-g $RG --environment $ACA_ENV \
--image docker.io/redis:7.0 --container-name redis \
--ingress internal --target-port 6379 --transport tcp \
--cpu 0.5 --memory 1Gi --min-replicas 1 

# Dapr component for redis 
az containerapp env dapr-component set --name $ACA_ENV --yaml ./deploy/az-cli/redis-component.yaml --dapr-component-name statestore-redis 

# SET ENV VARIABLES 
MY_ACR="acrignitealbumsdemo.azurecr.io"
ALBUM_API="album-api"
ALBUM_VIEWER="album-viewer"

# BUILD IMAGE AND PUSH ALBUM API 
docker build -t album-api:1.0 . 
az acr build -t album-api:{{.Run.ID}} -r $MY_ACR .

# DEPLOY ALBUM API TO ACA 
# Call out the automatic system identity is given acr pull access and used to pull the container image 
az containerapp create -n $ALBUM_API \
-g $RG --environment $ACA_ENV \
--image ${MY_ACR}/${ALBUM_API}:cj1 \
--registry-server $MY_ACR --registry-identity 'system' \
--container-name $ALBUM_API \
--ingress external --target-port 80 \
--cpu 0.5 --memory 1Gi --min-replicas 0 \
--enable-dapr true --dapr-app-id $ALBUM_API --dapr-app-port 80 --dal \
--env-vars 'PRODUCT_STATE_STORE=statestore-redis'

# DEPLOY ALBUM API TO ACA 
# Call out the automatic system identity is given acr pull access and used to pull the container image 
az containerapp create -n $ALBUM_VIEWER \
-g $RG--environment $ACA_ENV \
--image ${MY_ACR}/${ALBUM_API}:ADD_TAG_KENDALL \
--registry-server $MY_ACR --registry-identity 'system' \
--container-name$ALBUM_VIEWER \
--ingress external --target-port 80 \
--cpu 0.5 --memory 1Gi --min-replicas 0 \
--enable-dapr true --dapr-app-id $ALBUM_VIEWER --dapr-app-port 3000 --dal 

# add a health probe?? 

# Talk about switching the backends with dapr.. super easy and portable. 
add an environment variable to the album api container app that switches the backend component from statestore-redis to statestore-blob, make sure 
it has the appropriate managed identities etc. 