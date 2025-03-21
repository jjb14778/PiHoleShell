function Update-PiHoleGravity {
    <#
.SYNOPSIS
https://ftl.pi-hole.net/development-v6/docs/#post-/action/gravity

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER Gravity
True or False, if you set it to False when Blocking was set to true, it will update Gravity

.PARAMETER RawOutput
This will dump the response instead of the formatted object

.EXAMPLE
Update-PiHoleGravity -PiHoleServer "http://pihole.domain.com:8080" -Password "fjdsjfldsjfkldjslafjskdl" -Gravity True
    #>
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Does not change state')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
    param (
        $PiHoleServer,
        $Password,
        [ValidateSet("True", "False")]
        $Gravity,
        [bool]$RawOutput = $false
    )

    try {
        $Sid = Request-PiHoleAuth -PiHoleServer $PiHoleServer -Password $Password

        $Gravity = $Gravity.ToLower()

        $Body = "{`"gravity`":$Gravity}"
        $Params = @{
            Headers     = @{sid = $($Sid)
                Accept      = "application/json"
            }
            Uri         = "$PiHoleServer/api/action/gravity"
            Method      = "Post"
            ContentType = "application/json"
            Body        = $Body
        }

        $Response = Invoke-RestMethod @Params
		
        if ($RawOutput) {
            Write-Output $Response
        }

        else {
            if ($Response) {
                $ObjectFinal = @()
                $Object = [PSCustomObject]@{
                    GravityUpdate = "complete"
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

Export-ModuleMember -Function Update-PiHoleGravity
