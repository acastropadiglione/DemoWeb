$_version = 2.0
$_psdir = (get-item  $Args[0])
$_contentdir = "$_psdir\content"
$_pfdir = (${env:ProgramFiles(x86)}, ${env:ProgramFiles} -ne $null)[0]
$_vs="vs_buildtools.exe --add Microsoft.VisualStudio.Workload.WebBuildTools"
$_msbuild = "C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\MSBuild\15.0\Bin\msbuild.exe"
#region Remove content package (if exists)
If (Test-Path $_contentdir){
    Write-Host "`tRemoving content..."    
    Remove-Item "$_contentdir" -force -recurse
}
#endregion
#region Git
Write-Host "`tCloning content..." 
git clone --progress --branch 'master' 'https://github.com/acastropadiglione/DemoWeb.git' $_contentdir
#endregion
#region AssemblyInfo.cs
    Write-Host "`tReplacing version in Assembly Information..." 
    $_assemblyinfo = "$_psdir\WebAppBatata\Properties\AssemblyInfo.cs"
    $codeversion = Get-Content $_assemblyinfo | Select-String “assembly: AssemblyVersion”    
    $assemblyinfoversion = $codeversion -replace '\[assembly: AssemblyVersion\(\"','' -replace '\"\)\]','' -replace '\*', '\*'      
    (Get-Content $_assemblyInfo) | 
    Foreach-Object {$_ -replace $assemblyinfoversion, $_version}  | 
    Out-File $_assemblyinfo
#endregion
$_version = $_version -replace '\.', '_'
#region Projects Builds (Debug Any CPU)
#
    Write-Host "`tBuilding Debug Any CPU version..." 
    $global:LASTEXITCODE = 0
    $options = @((join-path $_contentdir 'WebAppBatata.sln'), '/m', '/p:Configuration=Debug', '/p:Platform=Any CPU')    
    #& $_msbuild $options '/t:Clean' | Out-Null
    #& $_msbuild $options '/t:Build' | Out-Null
    & $_msbuild $options '/t:Rebuild' | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Debug project build failed!"
    }
#
#endregion
#region Publish
    Write-Host "`tPublishing (Debug Any CPU)..."
    $global:LASTEXITCODE = 0
    $_webUIdir = "$_contentdir/WebAppBatata/WebAppBatata.csproj"
    $_publishdir = "$_psdir/ContentBR_RC_$_version/WebUI"
    $options = @(($_webuidir), '/m', "/p:VisualStudioVersion=14.0;Platform=AnyCPU;Configuration=Debug;WebPublishMethod=FileSystem;DeployDefaultTarget=WebPublish;publishUrl=$_publishdir")    
    #& $_msbuild $options '/t:Publish' | Out-Null
    & $_msbuild $options '/t:WebPublish'
    if ($LASTEXITCODE -ne 0) {
        throw "Publish failed!"
    }
#endregion
