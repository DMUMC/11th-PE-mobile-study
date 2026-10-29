$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$localRoot = Join-Path $projectRoot '.local'
$serverPath = Join-Path $localRoot 'mysql-8.4.13-winx64/bin/mysqld.exe'
$dataPath = Join-Path $localRoot 'mysql-data'
if (-not (Test-Path -LiteralPath $serverPath)) { throw '로컬 MySQL 실행 파일이 없습니다. README를 확인하세요.' }
if (-not (Test-Path -LiteralPath $dataPath)) { throw '로컬 MySQL 데이터 디렉터리가 아직 초기화되지 않았습니다.' }
if (Get-NetTCPConnection -State Listen -LocalPort 3307 -ErrorAction SilentlyContinue) {
  Write-Output '3307 포트가 이미 사용 중입니다. npm run db:check로 연결을 확인하세요.'
  exit
}
$serverOptions = @(
  ('--basedir="' + (Split-Path -Parent (Split-Path -Parent $serverPath)) + '"'),
  ('--datadir="' + $dataPath + '"'),
  '--port=3307',
  '--bind-address=127.0.0.1',
  '--mysqlx=OFF',
  ('--log-error="' + (Join-Path $localRoot 'mysql-server.log') + '"')
)
$process = Start-Process -FilePath $serverPath -ArgumentList $serverOptions -WindowStyle Hidden -PassThru
Write-Output ("MySQL 시작: PID " + $process.Id + ", 127.0.0.1:3307")
