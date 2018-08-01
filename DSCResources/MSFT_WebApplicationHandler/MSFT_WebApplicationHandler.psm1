# Load the Helper Module
Import-Module -Name "$PSScriptRoot\..\Helper.psm1"

# Import Localization Strings
$localizedData = Get-LocalizedData `
    -ResourceName 'MSFT_WebApplicationHandler' `
    -ResourcePath (Split-Path -Parent $Script:MyInvocation.MyCommand.Path)

<#
    .SYNOPSIS
        This will return a hashtable of results.

    .PARAMETER Name
        Specifies the name of the new request handler.

    .PARAMETER Path
        Specifies an IIS configuration path.

#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [System.String[]]
        $Path
    )

    $filter = "system.webServer/handlers/Add[@Name='" + $Name + "']"

    $webHandler = Get-WebConfigurationProperty -PSPath $Path -Filter $filter -Name '.'

    $returnValue = @{
        Name                = $webhandler.Name
        PhysicalHandlerPath = $webHandler.Path
        Verb                = $webHandler.Verb
        Type                = $webHandler.Type
        Modules             = $webHandler.Modules
        ScriptProcessor     = $webHandler.ScriptProcessor
        PreCondition        = $webHandler.PreCondition
        RequireAccess       = $webHandler.RequireAccess
        AllowPathInfo       = $webHandler.AllowPathInfo
        ResourceType        = $webHandler.ResourceType
        ResponseBufferLimit = $webHandler.ResponseBufferLimit
        Path                = $Path
    }

    if (-not [string]::IsNullOrEmpty($webHandler.Name))
    {
        Write-Verbose -Message ($localizedData.VerboseGetTargetPresent -f $Name)
        $returnValue.Add('Ensure', 'Present')
    }
    else
    {
        Write-Verbose -Message ($localizedData.VerboseGetTargetAbsent -f $Name)
        $returnValue.Add('Ensure', 'Absent')
    }

    return $returnValue
}

<#
    .SYNOPSIS
        This will set the desired state.

    .PARAMETER Ensure
        Specifies whether the handler should be present

    .PARAMETER Name
        Specifies the name of the new request handler.

    .PARAMETER PhysicalHandlerPath
        Specifies the physical path to the handler. This parameter applies to native modules only.

    .PARAMETER Verb
        Specifies the HTTP verbs that are handled by the new handler.

    .PARAMETER Path
        Specifies an IIS configuration path.

    .PARAMETER Type
        Specifies the managed type of the new module. This parameter applies to managed modules only.

    .PARAMETER Modules
        Specifies the modules used for the handler.

    .PARAMETER ScriptProcessor
        Specifies the script processor that runs for the module.

    .PARAMETER PreCondition
        Specifies preconditions for the new handler.

    .PARAMETER RequireAccess
        Specifies the user rights that are required for the new handler.
        Accepted values are None, Read, Write, Script, Execute.

    .PARAMETER ResourceType
        Specifies the type of resource to which the handler mapping applies.

    .PARAMETER AllowPathInfo
        Specifies whether the handler processes full path information in a URI,
        such as contoso/marketing/imageGallery.aspx. If the value is true, the
        handler processes the full path, contoso/marketing/imageGallery.
        If the value is false, the handler processes only the last section of
        the path, /imageGallery.

    .PARAMETER ResponseBufferLimit
        Specifies the maximum size, in bytes, of the response buffer for a request handler.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter()]
        [System.String]
        $PhysicalHandlerPath,

        [Parameter()]
        [System.String]
        $Verb,

        [Parameter(Mandatory = $true)]
        [System.String[]]
        $Path,

        [Parameter()]
        [System.String]
        $Type,

        [Parameter()]
        [System.String]
        $Modules,

        [Parameter()]
        [System.String]
        $ScriptProcessor,

        [Parameter()]
        [System.String]
        $PreCondition,

        [Parameter()]
        [ValidateSet('None', 'Read', 'Write', 'Script', 'Execute')]
        [System.String]
        $RequireAccess,

        [Parameter()]
        [System.String]
        $ResourceType,

        [Parameter()]
        [System.Boolean]
        $AllowPathInfo,

        [Parameter()]
        [System.uInt32]
        $ResponseBufferLimit
    )

    $filter = "system.webServer/handlers/Add[@Name='" + $Name + "']"

    $currentHandler = Get-TargetResource -Name $Name -Path $Path

    $null = $PSBoundParameters.Remove('Ensure')
    $null = $PSBoundParameters.Remove('Path')

    $attributes = @{}
    $PSBoundParameters.GetEnumerator() | ForEach-Object -Process {$attributes.add($_.Key, $_.Value)}

    # Rename PhysicalHandlerPath key to Path
    $attributes.Path = $attributes.PhysicalHandlerPath
    $null = $attributes.Remove('PhysicalHandlerPath')

    if ($Ensure -eq 'Present')
    {
        if ($currentHandler.Ensure -eq 'Present')
        {
            Write-Verbose -Message ($localizedData.UpdatingHandler -f $Name)
            Set-WebConfigurationProperty -Filter $filter -PSPath $Path -Name '.' -Value $attributes
        }
        else
        {
            Write-Verbose -Message ($localizedData.AddingHandler -f $Name)
            Add-WebConfigurationProperty -Filter 'system.webServer/handlers' -PSPath $Path -Name '.' -Value $attributes
        }
    }
    elseif ($Ensure -eq 'Absent')
    {
        if ($currentHandler.Ensure -eq 'Present')
        {
            Write-Verbose -Message ($localizedData.RemovingHandler -f $Name)
            Remove-WebHandler -Name $Name -PSPath $Path
        }
        else
        {
            Write-Verbose -Message 'Current Handler is in desired state (Absent)'
        }
    }
}

<#
    .SYNOPSIS
        This tests the desired state.
        If the state is not correct it returns $false.
        If the state is correct it returns $true.

    .PARAMETER Ensure
        Specifies whether the handler should be present

    .PARAMETER Name
        Specifies the name of the new request handler.

    .PARAMETER PhysicalHandlerPath
        Specifies the physical path to the handler. This parameter applies to native modules only.

    .PARAMETER Verb
        Specifies the HTTP verbs that are handled by the new handler.

    .PARAMETER Path
        Specifies an IIS configuration path.

    .PARAMETER Type
        Specifies the managed type of the new module. This parameter applies to managed modules only.

    .PARAMETER Modules
        Specifies the modules used for the handler.

    .PARAMETER ScriptProcessor
        Specifies the script processor that runs for the module.

    .PARAMETER PreCondition
        Specifies preconditions for the new handler.

    .PARAMETER RequireAccess
        Specifies the user rights that are required for the new handler.
        Accepted values are None, Read, Write, Script, Execute.

    .PARAMETER ResourceType
        Specifies the type of resource to which the handler mapping applies.

    .PARAMETER AllowPathInfo
        Specifies whether the handler processes full path information in a URI,
        such as contoso/marketing/imageGallery.aspx. If the value is true, the
        handler processes the full path, contoso/marketing/imageGallery.
        If the value is false, the handler processes only the last section of
        the path, /imageGallery.

    .PARAMETER ResponseBufferLimit
        Specifies the maximum size, in bytes, of the response buffer for a request handler.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter()]
        [System.String]
        $PhysicalHandlerPath,

        [Parameter()]
        [System.String]
        $Verb,

        [Parameter(Mandatory = $true)]
        [System.String[]]
        $Path,

        [Parameter()]
        [System.String]
        $Type,

        [Parameter()]
        [System.String]
        $Modules,

        [Parameter()]
        [System.String]
        $ScriptProcessor,

        [Parameter()]
        [System.String]
        $PreCondition,

        [Parameter()]
        [ValidateSet('None', 'Read', 'Write', 'Script', 'Execute')]
        [System.String]
        $RequireAccess,

        [Parameter()]
        [System.String]
        $ResourceType,

        [Parameter()]
        [System.Boolean]
        $AllowPathInfo,

        [Parameter()]
        [System.uInt32]
        $ResponseBufferLimit
    )

    $currentHandler = Get-TargetResource -Name $Name -Path $Path

    $inDesiredState = $true
    if ($Ensure -eq 'Absent')
    {
        if (-not [string]::IsNullOrEmpty($currentHandler.Name))
        {
            $inDesiredState = $false
        }
    }
    else #ensure -eq 'Present'
    {
        if ([string]::IsNullOrEmpty($currentHandler.Name))
        {
            $inDesiredState = $false
        }
        else
        {
            $currentHandler.Remove('Ensure')
            foreach ($key in $currentHandler.GetEnumerator())
            {
                $keyName = $key.Name
                if ($PSBoundParameters.$keyName -ne $currentHandler.$keyName)
                {
                    $inDesiredState = $false
                    Write-Verbose -Message ($localizedData.PropertyNotInDesiredState -f $keyName)
                }
            }
        }
    }

    return $inDesiredState
}

Export-ModuleMember -Function *-TargetResource