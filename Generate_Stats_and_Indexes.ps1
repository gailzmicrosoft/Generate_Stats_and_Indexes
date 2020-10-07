#======================================================================================================================#
#                                                                                                                      #                                                                                                                      #
#  This utility was developed on a best effort basis                                                                   #
#  to aid effort to migrate into Azure Synapse and then Optimize the Design for best performance.                      #                                                       #
#  It is not an officially supported Microsoft application or tool.                                                    #
#                                                                                                                      #
#  The utility and any script outputs are provided on "AS IS" basis and                                                #
#  there are no warranties, express or implied, including, but not limited to implied warranties of merchantability    #
#  or fitness for a particular purpose.                                                                                #
#                                                                                                                      #                    
#  The utility is therefore not guaranteed to generate perfect code or output. The output needs carefully reviewed.    #
#                                                                                                                      #
#                                       USE AT YOUR OWN RISK.                                                          #
#  Author: Gaiye "Gail" Zhou                                                                                           #
#  October 2020                                                                                                        #
#                                                                                                                      #
#                                                                                                                      #
#======================================================================================================================#
#
#
#
#==========================================================================================================
# Functions Start here 
#==========================================================================================================
#
# Capture Time Difference and Format time parts into easy to read or display formats. 
Function GetDuration() {
    [CmdletBinding()] 
    param( 
        [Parameter(Position = 1, Mandatory = $true)] [datetime]$StartTime, 
        [Parameter(Position = 1, Mandatory = $true)] [datetime]$FinishTime
    ) 

    $ReturnValues = @{ }

    $Timespan = (New-TimeSpan -Start $StartTime -End $FinishTime)

    $Days = [math]::floor($Timespan.Days)
    $Hrs = [math]::floor($Timespan.Hours)
    $Mins = [math]::floor($Timespan.Minutes)
    $Secs = [math]::floor($Timespan.Seconds)
    $MSecs = [math]::floor($Timespan.Milliseconds)

    if ($Days -ne 0) {

        $Hrs = $Days * 24 + $Hrs 
    }

    $DurationText = '' # initialize it! 

    if (($Hrs -eq 0) -and ($Mins -eq 0) -and ($Secs -eq 0)) {
        $DurationText = "$MSecs milliseconds." 
    }
    elseif (($Hrs -eq 0) -and ($Mins -eq 0)) {
        $DurationText = "$Secs seconds $MSecs milliseconds." 
    }
    elseif ( ($Hrs -eq 0) -and ($Mins -ne 0)) {
        $DurationText = "$Mins minutes $Secs seconds $MSecs milliseconds." 
    }
    else {
        $DurationText = "$Hrs hours $Mins minutes $Secs seconds $MSecs milliseconds."
    }

    $ReturnValues.add("Hours", $Hrs)
    $ReturnValues.add("Minutes", $Mins)
    $ReturnValues.add("Seconds", $Secs)
    $ReturnValues.add("Milliseconds", $MSecs)
    $ReturnValues.add("DurationText", $DurationText)

    return $ReturnValues 

}



######################################################################################
########### Main Program 
#######################################################################################

$ProgramStartTime = (Get-Date)

$ScriptPath = Split-Path $MyInvocation.MyCommand.Path -Parent
Set-Location -Path $ScriptPath

$cfgFilePath = Read-Host -prompt "Enter the Config File Path or press 'Enter' to accept the default [$($ScriptPath)]"
if ([string]::IsNullOrEmpty($cfgFilePath)) {
    $cfgFilePath = $ScriptPath
}

# CSV Config File
$defaultTablesCfgFile = "si_table_list.csv"
$tablesCfgFile = Read-Host -prompt "Enter the List of Tables Config Name or press 'Enter' to accept the default [$($defaultTablesCfgFile)]"
if ([string]::IsNullOrEmpty($tablesCfgFile)) {
    $tablesCfgFile = $defaultTablesCfgFile
}
$tablesCfgFileFullPath = join-path $cfgFilePath $tablesCfgFile
if (!(test-path $tablesCfgFileFullPath )) {
    Write-Host "Could not find Config File: $tablesCfgFileFullPath " -ForegroundColor Red
    break 
}

# use the $tablesCfgFile as prefix for output file names. 
$Config_File_WO_Extension = [System.IO.Path]::GetFileNameWithoutExtension($tablesCfgFile)

# To turn it off, specify the vaule '0' 
$CreateTableStatsFlag = '1'
$DropTableStatsFlag = '1' 

$UpdateTableStatsFullScanFlag = '1'
$UpdateTableStatsCustomScanFlag = '1' 

$RebuildTableIndexFlag = '1' 
$ReorganizeTableIndexFlag = '1' 



# Create Table Stats 
if ($CreateTableStatsFlag -ne '0') {
    $CreateTableStatsFile = $Config_File_WO_Extension + "_Create_Table_Stats.sql"
    $CreateTableStatsFileFullPath = join-path $ScriptPath $CreateTableStatsFile
    if (test-path  $CreateTableStatsFileFullPath ) {
        Write-Host "Previous File will be overwritten: " $CreateTableStatsFileFullPath  -ForegroundColor Yellow
        Remove-Item $CreateTableStatsFileFullPath   -Force
    }
    '/* Create Table Statistics */' >> $CreateTableStatsFileFullPath 
    $CodeGenerationTime = (Get-Date)
    "-- Code Generated at " + $CodeGenerationTime >> $CreateTableStatsFileFullPath 
    ' ' >> $CreateTableStatsFileFullPath 
}

# DropTable Stats 
if ($DropTableStatsFlag -ne '0') {
    $DropTableStatsFile = $Config_File_WO_Extension + "_Drop_Table_Stats.sql"
    $DropTableStatsFileFullPath = join-path $ScriptPath $DropTableStatsFile
    if (test-path  $DropTableStatsFileFullPath ) {
        Write-Host "Previous File will be overwritten: " $DropTableStatsFileFullPath  -ForegroundColor Yellow
        Remove-Item $DropTableStatsFileFullPath   -Force
    }
    '/* Drop Table Statistics */' >> $DropTableStatsFileFullPath 
    $CodeGenerationTime = (Get-Date)
    "-- Code Generated at " + $CodeGenerationTime >> $DropTableStatsFileFullPath 
    ' ' >> $DropTableStatsFileFullPath 
}


# Update Statistics for Tables with Full Scan 
if ($UpdateTableStatsFullScanFlag -ne '0') {
    $UpdateTableStatsFullScanFile = $Config_File_WO_Extension + "_Update_Table_Stats_FullScans.sql"
    $UpdateTableStatsFullScanFileFullPath = join-path $ScriptPath $UpdateTableStatsFullScanFile
    if (test-path  $UpdateTableStatsFullScanFileFullPath ) {
        Write-Host "Previous File will be overwritten: " $UpdateTableStatsFullScanFileFullPath  -ForegroundColor Yellow
        Remove-Item $UpdateTableStatsFullScanFileFullPath   -Force
    }
    '/* Update Table Stats With Full Scan */' >> $UpdateTableStatsFullScanFileFullPath 
    $CodeGenerationTime = (Get-Date)
    "-- Code Generated at " + $CodeGenerationTime >> $UpdateTableStatsFullScanFileFullPath 
    ' ' >> $UpdateTableStatsFullScanFileFullPath 
}

# Update Statistics for Tables with Custom Scan 
if ($UpdateTableStatsCustomScanFlag -ne '0') {
    $UpdateTableStatsCustomScanFile = $Config_File_WO_Extension + "_Update_Table_Stats_CustomScans.sql"
    $UpdateTableStatsCustomScanFileFullPath = join-path $ScriptPath $UpdateTableStatsCustomScanFile
    if (test-path  $UpdateTableStatsCustomScanFileFullPath ) {
        Write-Host "Previous File will be overwritten: " $UpdateTableStatsCustomScanFileFullPath  -ForegroundColor Yellow
        Remove-Item $UpdateTableStatsCustomScanFileFullPath   -Force
    }
    '/* Update Table Stats With Custom Scan Rage  */' >> $UpdateTableStatsCustomScanFileFullPath 
    $CodeGenerationTime = (Get-Date)
    "-- Code Generated at " + $CodeGenerationTime >> $UpdateTableStatsCustomScanFileFullPath 
    ' ' >> $UpdateTableStatsCustomScanFileFullPath 
}

# Rebuld Table Index 
if ($RebuildTableIndexFlag -ne '0') {
    $RedbuildTableIndexFile = $Config_File_WO_Extension + "_Rebuild_Table_Index.sql"
    $RedbuildTableIndexFileFullPath = join-path $ScriptPath $RedbuildTableIndexFile
    if (test-path  $RedbuildTableIndexFileFullPath ) {
        Write-Host "Previous File will be overwritten: " $RedbuildTableIndexFileFullPath  -ForegroundColor Yellow
        Remove-Item $RedbuildTableIndexFileFullPath   -Force
    }
    '/* Rebuild Table Index */' >> $RedbuildTableIndexFileFullPath 
    $CodeGenerationTime = (Get-Date)
    "-- Code Generated at " + $CodeGenerationTime >> $RedbuildTableIndexFileFullPath 
    ' ' >> $RedbuildTableIndexFileFullPath 
    "-- Please scale up Synapse SQL Pool before you execute this code. " >> $RedbuildTableIndexFileFullPath 
    ' ' >> $RedbuildTableIndexFileFullPath 
}

# Reorganize Table Index 
if ($ReorganizeTableIndexFlag -ne '0') {
    $ReorganizeTableIndexFile = $Config_File_WO_Extension + "_Reorganize_Table_Index.sql"
    $ReorganizeTableIndexFileFullPath = join-path $ScriptPath $ReorganizeTableIndexFile
    if (test-path  $ReorganizeTableIndexFileFullPath ) {
        Write-Host "Previous File will be overwritten: " $ReorganizeTableIndexFileFullPath  -ForegroundColor Yellow
        Remove-Item $ReorganizeTableIndexFileFullPath   -Force
    }
    '/* Reorganize Table Index */' >> $ReorganizeTableIndexFileFullPath 
    $CodeGenerationTime = (Get-Date)
    "-- Code Generated at " + $CodeGenerationTime >> $ReorganizeTableIndexFileFullPath 
    ' ' >> $ReorganizeTableIndexFileFullPath 
    "-- Please scale up Synapse SQL Pool before you execute this code. " >> $ReorganizeTableIndexFileFullPath 
    ' ' >> $ReorganizeTableIndexFileFullPath 
}

#==============================================================================
# Now processing each line of the .csv file. Looping through! 
#==============================================================================
Write-Host "  I am working on the tasks! Will report to you once done. " -ForegroundColor Cyan

$csvTablesCfgFile = Import-Csv $tablesCfgFileFullPath
ForEach ($csvItem in $csvTablesCfgFile) {
    $Active = $csvItem.Active
    If ($Active -eq "1") {
        $DatabaseName = $csvItem.DatabaseName
        $SchemaName = $csvItem.SchemaName
        $TableName = $csvItem.TableName
        $StatsColumns = $csvItem.StatsColumns
        $StatsScanRate = $csvItem.StatsScanRate

        if ( ![string]::IsNullOrEmpty($StatsColumns) -and [string]::IsNullOrEmpty($StatsScanRate) )
        {
            Write-Host " For $SchemaName.$TableName StatsColumns defined but StatsScanRate not defined. I am setting it as 100."  -ForegroundColor Magenta
            $StatsScanRate = 100

        }

        # Create Table Stats 
        if ($CreateTableStatsFlag -eq '1') {
            if ( [string]::IsNullOrEmpty($StatsColumns) ) {
                # Will not create statistics 
                Write-Host " Skipped Stats Creation for this table since [StatsColumns] field was empty: " $SchemaName"."$TableName -ForegroundColor Yellow
            }
            else {
                # Below cast is critical to get the correct results! 
                $StatsScanRateInt = [int] $StatsScanRate 
                if (($StatsScanRateInt -lt 0) -or ($StatsScanRateInt -gt 100)) {
                    "-- Did not get expected specifications for this table. StatsScanRate was set " + $StatsScanRate >>  $CreateTableStatsFileFullPath 
                    "-- Set to create Stats with Full Scan. " >>  $CreateTableStatsFileFullPath 
                    "-- Check your config file and re-run Powershell Code Generation program if needed. " >>  $CreateTableStatsFileFullPath 
                    $StatsScanRate = 100
                }

                $splitvars = $StatsColumns.Split("|")
                $len = $splitvars.count 
                $i = 0 
                $hasyKeysCombined = ''
                ForEach ($var in $splitvars) {
                    $i = $i + 1 
                    If ($i -lt $len) {
                        $hasyKeysCombined = $var + "," 
                    }
                    else {
                        $hasyKeysCombined = $hasyKeysCombined + $var 
                    }
                }
                "CREATE STATISTICS " + "STATS_" + $SchemaName + "_" + $TableName  >>  $CreateTableStatsFileFullPath 
                " ON " + $DatabaseName + "." + $SchemaName + "." + $TableName >>  $CreateTableStatsFileFullPath 
                " (" + $hasyKeysCombined + ")">>  $CreateTableStatsFileFullPath 
                if ($StatsScanRate -eq '100') {
                    "WITH FULLSCAN" >>  $CreateTableStatsFileFullPath

                }
                else {
                    " WITH SAMPLE " + $StatsScanRate + " PERCENT; " >> $CreateTableStatsFileFullPath
                }
                "GO " >>  $CreateTableStatsFileFullPath 
                " " >>  $CreateTableStatsFileFullPath 
            }
        }


        # Drop Table Statistics 
        if ($DropTableStatsFlag -eq '1') {

            if ( [string]::IsNullOrEmpty($StatsColumns) ) {
                # Do nothing for this task 
            }
            else {
                $StatsName = $SchemaName + "." + $TableName + "." + "STATS_" + $SchemaName + "_" + $TableName

                "DROP STATISTICS " + $StatsName >>  $DropTableStatsFileFullPath 
                "GO " >>  $DropTableStatsFileFullPath 
                " " >>  $DropTableStatsFileFullPath 
            }

           
        }

        # Update Table Stats With Full Scan 
        if ($UpdateTableStatsFullScanFlag -eq '1') {
            if ( [string]::IsNullOrEmpty($StatsColumns) ) {
                Write-Host " Update Stats with Full Scan. Skipped this table as stats was not created for it: " $SchemaName"."$TableName -ForegroundColor Yellow 
                "--Skipped this table as stats was not created for it: " + $SchemaName + "." + $TableName >>  $UpdateTableStatsFullScanFileFullPath
                " " >>  $UpdateTableStatsFullScanFileFullPath 
            }
            else {
                "UPDATE STATISTICS " + $SchemaName + "." + $TableName + " WITH FULLSCAN; ">>  $UpdateTableStatsFullScanFileFullPath 
                "GO " >>   $UpdateTableStatsFullScanFileFullPath 
                " " >>  $UpdateTableStatsFullScanFileFullPath 
            }
           
        }

        # Update Table Stats With Custom Scan 
        if ($UpdateTableStatsCustomScanFlag -eq '1') {
            if ( [string]::IsNullOrEmpty($StatsColumns) ) {
                Write-Host " Update Stats with Custom Scan. Skipped this table as stats was not created for it: " $SchemaName"."$TableName -ForegroundColor Yellow 
                "--Skipped this table as stats was not created for it: " + $SchemaName + "." + $TableName >>  $UpdateTableStatsCustomScanFileFullPath 
                " " >>  $UpdateTableStatsCustomScanFileFullPath 
            }
            else {
                # Below cast is critical to get the correct results! 
                $StatsScanRateInt = [int] $StatsScanRate 
                if (($StatsScanRateInt -lt 0) -or ($StatsScanRateInt -gt 100)) {
                    "-- Did not get expected specifications for this table. " >>  $UpdateTableStatsCustomScanFileFullPath 
                    "-- StatsScanRate was set " + $StatsScanRate >>  $UpdateTableStatsCustomScanFileFullPath
                    "-- Set to create Stats with Full Scan. " >>  $UpdateTableStatsCustomScanFileFullPath 
                    "-- Check your config file and re-run Powershell Code Generation program if needed. " >>  $UpdateTableStatsCustomScanFileFullPath 
                    $StatsScanRate = 100
                }

                "UPDATE STATISTICS " + $SchemaName + "." + $TableName + " WITH SAMPLE " + $StatsScanRate + " PERCENT;">>  $UpdateTableStatsCustomScanFileFullPath 
                "GO " >>   $UpdateTableStatsCustomScanFileFullPath
                " " >>  $UpdateTableStatsCustomScanFileFullPath
            }
          
        }


        # Rebuild Table Index 
        if ($RebuildTableIndexFlag -eq '1') {
            "ALTER INDEX ALL ON " + $SchemaName + "." + $TableName + " REBUILD; ">>  $RedbuildTableIndexFileFullPath 
            "GO " >>   $RedbuildTableIndexFileFullPath 
            " " >>  $RedbuildTableIndexFileFullPath 
 
        }

        # Reorganize Table Index 
        if ($ReorganizeTableIndexFlag -eq '1') {
            "ALTER INDEX ALL ON " + $SchemaName + "." + $TableName + " REORGANIZE; ">>  $ReorganizeTableIndexFileFullPath 
            "GO " >>  $ReorganizeTableIndexFileFullPath 
            " " >>  $ReorganizeTableIndexFileFullPath 
 
        }


    }

}


$ProgramFinishTime = (Get-Date)

$ProgDuration = GetDuration  -StartTime  $ProgramStartTime -FinishTime $ProgramFinishTime

Write-Host "Total time runing this program: " $ProgDuration.DurationText 
Write-Host "  Done! Have a great day!" -ForegroundColor Cyan
