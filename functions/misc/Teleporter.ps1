Function Export-PiHoleConfig {
    <#
.SYNOPSIS
https://ftl.pi-hole.net/development-v6/docs/#get-/teleporter

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER ConfigFile
Specify the Pihole Teleporter Config zip export file

.PARAMETER RawOutput
This will dump the response instead of the formatted object

.EXAMPLE
Export-PiHoleConfig -PiHoleServer "http://pihole.domain.com:8080" -Password "fjdsjfldsjfkldjslafjskdl" -ConfigFile "c:\config.zip"
    #>
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
    param (
        $PiHoleServer,
        $Password,
        $ConfigFile,
        [bool]$RawOutput = $false
    )
    try {
        $Sid = Request-PiHoleAuth -PiHoleServer $PiHoleServer -Password $Password

        $Params = @{
            Headers     = @{sid = $($Sid) }
            Uri         = "$PiHoleServer/api/teleporter"
            Method      = "Get"
            ContentType = "application/json"
        }

        $Data = Invoke-RestMethod @Params -OutFile $ConfigFile

        if ($RawOutput) {
            Write-Output $Data
        }
        else {
            $ObjectFinal = @()
            $Object = [PSCustomObject]@{
                ExportConfig = "Complete"
            }

            $ObjectFinal += $Object
            Write-Output $ObjectFinal
        }

    }

    catch {
        Write-Error -Message $_.Exception.Message
        break
    }

    finally {
        if ($Sid) {
            Remove-PiHoleCurrentAuthSession -PiHoleServer $PiHoleServer -Sid $Sid
        }
    }
}

function Import-PiHoleConfig {
    <#
.SYNOPSIS
https://ftl.pi-hole.net/development-v6/docs/#post-/teleporter

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER ConfigFile
Specify the Pihole Teleporter Config zip import file

.PARAMETER Gravity
True or False, if you set it to False when Blocking was set to true, it will update Gravity after import

.PARAMETER RawOutput
This will dump the response instead of the formatted object

.EXAMPLE
Import-PiHoleConfig -PiHoleServer "http://pihole.domain.com:8080" -Password "fjdsjfldsjfkldjslafjskdl" -ConfigFile "c:\config.zip" -Gravity True
    #>
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Does not change state')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
    param (
        $PiHoleServer,
        $Password,
        [ValidateSet("True", "False")]
        $Gravity,
        $ConfigFile,
        [bool]$RawOutput = $false
    )

    try {
        $Sid = Request-PiHoleAuth -PiHoleServer $PiHoleServer -Password $Password
        $jsonRestoreOptions='{
          "config": true,
          "dhcp_leases": true,
          "gravity": {
            "group": true,
            "adlist": true,
            "adlist_by_group": true,
            "domainlist": true,
            "domainlist_by_group": true,
            "client": true,
            "client_by_group": true
          }
        }'

        $jsonConfigFile = @{ 
            file=$ConfigFile # no leading @ sign.
        }

        $Params = @{
            Headers     = @{sid = $($Sid)
                Accept      = "multipart/form-data"
            }
            Uri         = "$PiHoleServer/api/teleporter"
            ContentType = "multipart/form-data"
            Body        = $BodyCMDhashtable
        }
        
        $BodyCMDhashtable = @{} # Create body Hashtable from json
        $jsonRestoreOptions.psobject.properties | Foreach { $BodyCMDhashtable[$_.Name] = $_.Value }
        $jsonConfigFile.psobject.properties | Foreach { $BodyCMDhashtable[$_.Name] = $_.Value }
                
        $Response = Invoke-RestMethod @Params
        if ($Gravity) {
            $ResponseGravity = Update-PiHoleGravity -PiHoleServer $PiHoleServer -Password $Password -Gravity $Gravity -RawOutput $RawOutput
        }		
        if ($RawOutput) {
            Write-Output $Response
            write-output $ResponseGravity
        }

        else {
            if ($Response) {
                $ObjectFinal = @()
                $Object = [PSCustomObject]@{
                    ImportConfig = "complete"
                    GravityUpdate = $Gravity
                }
                $ObjectFinal = $Object
            }
            Write-Output $ObjectFinal
        }

    }

    catch {
        Write-Error -Message $_.Exception.Message
    }

    finally {
        if ($Sid) {
            Remove-PiHoleCurrentAuthSession -PiHoleServer $PiHoleServer -Sid $Sid
        }
    }
}

Export-ModuleMember -Function Export-PiHoleConfig, Import-PiHoleConfig
