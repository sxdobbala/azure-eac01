<#
Project Backup Script would generate Mysql Dump (.sql) file which has the metadata information and Project configuration (.scp).

Below are the process involved:
1) Create system tables in empty database.
2) Run Project Migration (Project Duplication from 3-tier to 2-tier).
3) Create mysqldump file.
4) Backup Project configuration.

Prerequisites:
1) Create 2-tier project source.
2) Create a dsn pointing to empty mysql database.
#>

$basePath = $env:ProgramData+"\MSTRProjectMigration\Runs\"
$duplicationXmlTemplatePath = $env:ProgramData+"\MSTRProjectMigration\Config\ProjectDuplication.xml"
$currDate = Get-Date -Format yyyyMMdd_HHmm
$databaseBackupLocation = $env:ProgramData+"\MSTRProjectMigration\MetadataBackups"
$mstrSystemTablesScript =  $env:ProgramData+"\MSTRProjectMigration\Config\opa_metadata_blank.sql"
$commandManagerPath = "C:\Program Files (x86)\MicroStrategy\Command Manager\CMDMGR.exe"
$generateProjConfigScript = $env:ProgramData+"\MSTRProjectMigration\Config\ProjectConfig.scp"
$mysqlLocation = "C:\Program Files (x86)\Common Files\MicroStrategy\MySQL\mysql-5.6.28-winx64\bin\"
$logFilePath = $basePath+"LogFile_"+$currDate+".csv"



function MigrateProject([string] $sourceProjectSource,[string] $sourceUserName,[securestring] $sourcePassword,[string] $destinationProjectSource,[string] $destinationUserName,[securestring] $destinationPassword)
{
    $foldername = $sourceProjectSource.Replace(' ','')

    $path = $basePath+$foldername


    #Creating Environment folders
    CreateFolders -path $path

    #Using project duplication xml template to create a custom xml
    $fileContents = Get-Content $duplicationXmlTemplatePath

    $sourcePasswordText = ConvertFrom-SecureToPlain $sourcePassword

    $destinationPasswordText = ConvertFrom-SecureToPlain $destinationPassword

    $fileContents.Replace('[source]', $sourceProjectSource).
                  Replace('[destination]', $destinationProjectSource).
                  Replace('[sourceuser]', $sourceUserName).
                  Replace('[destinationuser]', $destinationUserName).
                  Replace('[path]',$path).
                  Replace('[Date]',$currDate) | Set-Content $path\Config\ProjectDuplication_$currDate.xml

    #invoke project duplication
    $dupScript = "ProjectDuplicate.exe -sup -f ""$path\Config\ProjectDuplication_$currDate.xml"" -sp $sourcePasswordText -dp $destinationPasswordText"

    $scriptBlock = [Scriptblock]::Create($dupScript)

    Start-Job  -ScriptBlock $scriptBlock

    #check status of the process
    CheckStatus -path $path -dupScript $dupScript | Out-Null
}

function CreateFolders([string] $path)
{
    New-Item -ItemType Directory -Force -Path $basePath
    New-Item -ItemType Directory -Force -Path $path
    New-Item -ItemType Directory -Force -Path $path\Config
    New-Item -ItemType Directory -Force -Path $path\Logs
    New-Item -ItemType Directory -Force -Path $databaseBackupLocation
}

function GenerateSQLDump([string] $databaseHostname,[string] $databaseUsername,[securestring] $databasePassword,[string] $metadataDBName)
{

    $PasswordPlainText = ConvertFrom-SecureToPlain $databasePassword

    [string] $saveFilePath = [string]::format("{0}\{1}_{2}.sql", $databaseBackupLocation, $metadataDBName, $currDate);

    $logFileFullPath = [string]::format("{0}\{1}_{2}.log", $databaseBackupLocation, $metadataDBName, $currDate);

    Write-Log -Message "Backing up project meta data in MySQL Database" -Severity Information


    $command = [string]::format(".\mysqldump.exe -u {0} -p{1} -h {2} --quick --default-character-set=utf8 --routines --events `"{3}`" > `"{4}`"",
            $databaseUsername,
            $PasswordPlainText,
            $databaseHostname,
            $metadataDBName,
            $saveFilePath);

    Write-Host $command

    $mysqlDumpStatus = Invoke-Expression "& $command";  # Execute mysqldump with the required parameters for each database

    $MyFile = Get-Content $saveFilePath
    $Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $True
    $MyPathOut = [string]::format("{0}\{1}_{2}_utf8.sql", $databaseBackupLocation, $metadataDBName, $currDate); # export it here without BOM
    [System.IO.File]::WriteAllLines($MyPathOut, $MyFile, $Utf8NoBomEncoding)

    if($mysqlDumpStatus.ExitCode -ne 0)
    {
        $errorMessage =  "Successful: Archive file is in "+$saveFilePath
        Write-Log -Message $errorMessage -Severity Information
    }
    else
    {
        Write-Log -Message "SqlDump Execution failed" -Severity Error
    }
}


function CheckStatus([string] $path)
{
    $logFile = "$path\Logs\ProjectDuplication_$currDate.log"

    Start-Sleep -s 60

    if(-Not (Test-Path $logFile))
    {
        throw "Project duplication process did not start"
    }

    Write-Log -Message "Started Project Duplication" -Severity Information

    while(1)
    {
    try
    {
        #Check the project duplication log for completion
        $line = Get-Content -Tail 1 -Path $logFile

        if ($line | Select-String -Pattern "Duplication Finished!" ){
            Write-Log -Message "Project Backup and Restore successful!" -Severity Information
            break;
        }

        #Terminate project duplication process if no logs are updated for 10 minutes
        [DateTime] $lastModifiedDate = $line.Substring($line.IndexOf('[')+1,$line.IndexOf(']')-1)
        [DateTime] $currentTime = Get-Date

        $timeSinceLastUpdate = ($currentTime - $lastModifiedDate).TotalMinutes
        if($timeSinceLastUpdate -gt 10) {
                   $errorMessage = "Project duplication logs not updated since last $timeSinceLastUpdate mintues."
                   Write-Log -Message $errorMessage -Severity Error
                    throw $errorMessage
        }
      }
      catch
      {
         Write-Log -Message "Error at handling time stamps" -Severity Information
      }

        Start-Sleep -s 30
    }
}

function ConvertFrom-SecureToPlain {

    param( [Parameter(Mandatory=$true)][System.Security.SecureString] $SecurePassword)

    # Create a "password pointer"
    $PasswordPointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePassword)

    # Get the plain text version of the password
    $PlainTextPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto($PasswordPointer)

    # Free the pointer
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($PasswordPointer)

    # Return the plain text password
    $PlainTextPassword
}

function PrepareDatabase([string] $databaseHostname,[string] $databaseUsername,[securestring] $databasePassword,[string] $metadataDBName)
{

    $PasswordPlainText = ConvertFrom-SecureToPlain $databasePassword

    Set-Location $mysqlLocation

    $command = [string]::format(".\mysql -h {3} -u {0} -p{1} -D `"information_schema`" -e `"DROP DATABASE IF EXISTS {2}; CREATE DATABASE {2}`"",
            $databaseUsername,
            $PasswordPlainText,
            $metadataDBName,
            $databaseHostname);


    $dbcreationstatus = Invoke-Expression "& $command";

    if($dbcreationstatus.ExitCode -ne 0)
    {

        $restoreDBLog = ("{0}\{1}_{2}.log" -f $databaseBackupLocation, $metadataDBName, $currDate);

        $restoreStatus = Invoke-Expression "get-content $mstrSystemTablesScript | & .\mysql.exe -h $databaseHostname -u $databaseUsername --password=$PasswordPlainText $metadataDBName >$restoreDBLog"

        Write-Host $restoreStatus.ExitCode

        if($restoreStatus.ExitCode -ne 0)
        {
            Write-Log -Message "Restore Successful" -Severity Information
        }
        else
        {
            Write-Log -Message "Exited with status code $restoreStatus.ExitCode" -Severity Warning
        }
    }
    else
    {
        Write-Log -Message "Database Creation Failed" -Severity Error
    }

}

function ExecuteCommand([string] $UserName,[securestring] $Password, [string] $ProjectSourceName,[string] $script)
{
    $passwordPlainText = ConvertFrom-SecureToPlain $databasePassword

    $executionStatus = & $commandManagerPath -n $ProjectSourceName -u $UserName -p $PasswordPlainText -showoutput -f $script -o $script".log"

    if($executionStatus.ExitCode -ne 0)
    {
        Write-Log -Message "Command Executed Successfully" -Severity Information
    }
    else
    {
        $errorMessage = $executionStatus.ExitCode.ToString
        Write-Log -Message $errorMessage  -Severity Information
        Write-Log -Message "Command Execution failed" -Severity Error
    }

}

function Write-Log
{
     [CmdletBinding()]
     param(
         [Parameter()]
         [ValidateNotNullOrEmpty()]
         [string]$Message,

         [Parameter()]
         [ValidateNotNullOrEmpty()]
         [ValidateSet('Information','Warning','Error')]
         [string]$Severity
     )

     [pscustomobject]@{
         Time = (Get-Date -f g)
         Message = $Message
         Severity = $Severity
     } | Export-Csv -Path $logFilePath -Append -NoTypeInformation
 }


function Main
{
    param
    (
        [Parameter(Mandatory = $false)]
        [string] $databaseHostname="localhost",

        [Parameter(Mandatory = $false)]
        [string] $databaseUsername="mstrbackup",

        [Parameter(Mandatory = $true)]
        [securestring] $databasePassword,

        [Parameter(Mandatory = $false)]
        [string] $metadataDBName="prodbackup",

        [Parameter(Mandatory = $false)]
        [string] $sourceProjectSource = "OPA DEV",

        [Parameter(Mandatory = $false)]
        [string] $sourceUserName="JothiD",

        [Parameter(Mandatory = $true)]
        [securestring] $sourcePassword,

        [Parameter(Mandatory = $false)]
        [string] $destinationProjectSource="OPADev2Tier",

        [Parameter(Mandatory = $false)]
        [string] $destinationUserName="Administrator",

        [Parameter(Mandatory = $true)]
        [securestring] $destinationPassword
    )

    #Microstrategy system tables are created in blank metadata db
    PrepareDatabase -databaseHostname $databaseHostname -databaseUsername $databaseUsername -databasePassword $databasePassword -metadataDBName $metadataDBName

    #Calling Project Migration from On-Prim to AWS
    MigrateProject -sourceProjectSource $sourceProjectSource -sourceUserName $sourceUserName -sourcePassword $sourcePassword -destinationProjectSource $destinationProjectSource -destinationUserName $destinationUserName -destinationPassword $destinationPassword

    #Calling SQL Dump to export metadata
    GenerateSQLDump -databaseHostname $databaseHostname -databaseUsername $databaseUsername -databasePassword $databasePassword -metadataDBName $metadataDBName

    #Backup Project Configuration from On-Prim project
    ExecuteCommand -UserName $sourceUserName -Password $sourcePassword -ProjectSourceName $sourceProjectSource -script $generateProjConfigScript
}

<# Calling Main method to start the job #>
Main
