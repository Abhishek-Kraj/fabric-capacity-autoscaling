#!/bin/bash

# Fabric Capacity Auto-Scaling Deployment Script

# Configuration - UPDATE THESE VALUES
RESOURCE_GROUP="<YOUR_RESOURCE_GROUP>"
LOGIC_APP_NAME="<YOUR_LOGIC_APP_NAME>"
LOCATION="westeurope"

echo "=== Fabric Capacity Auto-Scaling Deployment ==="
echo ""

# Check if Azure CLI is logged in
if ! az account show &> /dev/null; then
    echo "Please login to Azure CLI first: az login"
    exit 1
fi

# Create Logic App if it doesn't exist
echo "Checking Logic App..."
if ! az logic workflow show --resource-group $RESOURCE_GROUP --name $LOGIC_APP_NAME &> /dev/null; then
    echo "Creating Logic App: $LOGIC_APP_NAME"
    az logic workflow create \
        --resource-group $RESOURCE_GROUP \
        --name $LOGIC_APP_NAME \
        --location $LOCATION \
        --definition workflow.json
else
    echo "Updating Logic App: $LOGIC_APP_NAME"
    az logic workflow update \
        --resource-group $RESOURCE_GROUP \
        --name $LOGIC_APP_NAME \
        --definition workflow.json
fi

echo ""
echo "Deployment complete!"
echo ""
echo "Next steps:"
echo "1. Enable Managed Identity on the Logic App"
echo "2. Grant Contributor role on Fabric Capacity"
echo "3. Create Office 365 API connection"
echo "4. Update parameters with your values"
