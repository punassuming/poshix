trap #trap exceptions and force failure
{
    write-output $_
    exit 1
}

Import-Module Pester
Set-StrictMode -Version Latest
Import-Module agent-api -ErrorAction SilentlyContinue

$Results = Invoke-Pester -PassThru .\Tests
if (Get-Command "Add-AppveyorTest" -ErrorAction SilentlyContinue) {
    $failures = 0;
    foreach($test in $Results.Tests) {
        $outcome = "Failed";
        if ($test.Result -eq 'Passed') {
            $outcome = "Passed";
        } else {
            $failures++;
        }
        
        Add-AppveyorTest -Name $test.Name -Outcome $outcome -Duration $test.Duration.TotalMilliseconds -ErrorMessage $test.ErrorRecord.DisplayErrorMessage -ErrorStackTrace $test.ErrorRecord.DisplayStackTrace
    }
    exit $failures;
} else {}