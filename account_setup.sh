#!/usr/bin/env bash

set -euox pipefail

RESOURCE_GROUP='terraform'
STORAGE_ACCOUNT_PREFIX='labtfstate'
CONTAINER='tfstate'
SUBSCRIPTION_NAME='Visual Studio Professional Subscription'
SUBSCRIPTION_ID='8236f5fd-e7f5-4175-85f8-0dfa1ea886f5'

REGIONS=(
    southindia:in
)

SUBSCRIPTIONS=(
    Visual Studio Professional Subscription:8236f5fd-e7f5-4175-85f8-0dfa1ea886f5
)

# given that we will implement DR in phase 2, I am keeping the regions as list.
for region in "${REGIONS[@]}"
do
    REGION_NAME=${region%:*}
    REGION_ID=${region#*:}
    STORAGE_ACCOUNT="${STORAGE_ACCOUNT_PREFIX}${REGION_ID}"
    RESOURCE_GROUP_NAME="${RESOURCE_GROUP}-${REGION_NAME}"
    az account set --subscription="${SUBSCRIPTION_ID}"
    az group create \
        --name "${RESOURCE_GROUP_NAME}" \
        --location "${REGION_NAME}"

    az storage account create \
        --name "${STORAGE_ACCOUNT}" \
        --resource-group "${RESOURCE_GROUP_NAME}" \
        --location "${REGION_NAME}" \
        --sku Standard_LRS \
        --encryption-services blob \
        --https-only true

    export AZURE_STORAGE_ACCOUNT="${STORAGE_ACCOUNT}"
    AZURE_STORAGE_ACCESS_KEY="$(az storage account keys list --account-name "${STORAGE_ACCOUNT}" --resource-group "${RESOURCE_GROUP_NAME}" | jq -r '.[0].value')"
    export AZURE_STORAGE_ACCESS_KEY

    az storage container create --name "${CONTAINER}"
done

