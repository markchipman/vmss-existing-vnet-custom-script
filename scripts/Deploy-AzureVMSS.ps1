#-------------------------------------------------------------------------
# Copyright (c) Microsoft.  All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#--------------------------------------------------------------------------

#region Sign-in with Azure account

    $Error.Clear()

    Login-AzureRmAccount

#endregion

#region Select Azure Subscription

    $subscriptionId = 
        ( Get-AzureRmSubscription |
            Out-GridView `
              -Title "Select an Azure Subscription ..." `
              -PassThru
        ).SubscriptionId

    Select-AzureRmSubscription `
        -SubscriptionId $subscriptionId

#endregion

#region Specify unique deployment name prefix (up to 6 alphanum chars)

    $NamePrefix = -join ((97..122) | Get-Random -Count 6 | % {[char]$_})

#endregion

#region Prompt for Admin credentials for new VMSS instances

    $AdminCreds = Get-Credential -Message "Enter Admin Username and Password"

    $AdminUsername = $AdminCreds.UserName

    $AdminPassword = $AdminCreds.GetNetworkCredential().Password

#endregion

#region Define hash table for parameter values

    $ARMTemplateParams = @{
        "vmssName" = "$NamePrefix";
        "adminUsername" = "$AdminUsername";
        "adminPassword" = "$AdminPassword"
    }

#endregion

#region Deploy to Azure

    $rgName = "${NamePrefix}-rg"
    $deploymentName = "${NamePrefix}-deploy"
    $location = "southeastasia"
    $artifactsLocation = "https://raw.githubusercontent.com/robotechredmond/vmss-existing-vnet-custom-script/master"
    $artifactsLocationSasToken = ""

    try
    {

        New-AzureRmResourceGroup -Name $rgName -Location $location 

        New-AzureRmResourceGroupDeployment `
            -Name $deploymentName `
            -ResourceGroupName $rgName `
            -TemplateParameterObject $ARMTemplateParams `
            -TemplateUri "${artifactsLocation}/azuredeploy.json${artifactsLocationSasToken}" `
            -Mode Incremental `
            -ErrorAction Stop `
            -Confirm

    }
    catch 
    {
        Write-Error -Exception $_.Exception
    }

#endregion

#region Clear deployment parameters

    $ARMTemplateParams = @{}

#endregion
