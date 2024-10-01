# Parte 2: Script para realizar o POST

# Caminhos
$destinationPath = "C:\ProgramData\WenzPostScript\userassistview"
$executablePath = "$destinationPath\UserAssistView.exe"
$csvFilePath = "$destinationPath\programs.csv"
$logFile = "$destinationPath\LogPostScript.txt"

# Função para escrever no log
function Write-Log {
    param ([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp - $message"
    Add-Content -Path $logFile -Value $logMessage
}

# Função para gerar id_UserMqn com base no Hostname e Username (em Base64)
function Get-IdUserMqn {
    $hostname = [System.Net.Dns]::GetHostName()
    $username = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    $combinedString = "$hostname-$username"
    $id_UserMqn = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($combinedString))
    return $id_UserMqn
}

# Função para controlar o número da execução
function Get-ExecutionNumber {
    $logFileExec = "C:\ProgramData\WenzPostScript\userassistview\log_execution_number.txt"
    
    if (Test-Path $logFileExec) {
        $executionNumber = Get-Content $logFileExec
        $executionNumber = [int]$executionNumber
        
        if ($executionNumber -ge 5) {
            $executionNumber = 1
        } else {
            $executionNumber++
        }
    } else {
        $executionNumber = 1
    }
    
    Set-Content -Path $logFileExec -Value $executionNumber
    return $executionNumber
}

# Função para executar o POST
function Process-And-Upload {
    Write-Log "Processando o arquivo CSV..."
    
    if (Test-Path $csvFilePath) {
        $executionNumber = Get-ExecutionNumber
        $id_UserMqn = Get-IdUserMqn
        $hostname = [System.Net.Dns]::GetHostName()
        $username = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
        Write-Log "Execution Number $executionNumber"
        
        $programs = Get-Content $csvFilePath
        $numLinhas = $programs.Length
        $counter = 1
        Write-Log "Programas Encontrados: $numLinhas"
        
        $programList = @()
        
        $programs | ForEach-Object {
            Write-Host "Processando Programa $counter/$numLinhas"
            $counter += 1
            $fields = $_ -split ","
            $programData = [pscustomobject]@{
                Program      = [string]$fields[0]
                indice       = [int]$fields[1]
                count        = if ($fields[2] -ne "") { [string]$fields[2] } else { "N/A" }
                GUID         = [string]$fields[3]
                User         = $username
                Hostname     = $hostname
                id_UserMqn   = $id_UserMqn
                id_execution = $executionNumber.ToString()
                program_id   = "$($fields[1])-$($executionNumber)"
            }
            $programList += $programData
        }

        $jsonBody = $programList | ConvertTo-Json

        $apiUrl = "http://zabbix.wenz.com.br:8000/programs"

        try {
            $response = Invoke-RestMethod -Uri $apiUrl -Method Post -Body $jsonBody -ContentType "application/json"
            Write-Log "Dados enviados com sucesso para $apiUrl. Resposta: $response"
        }
        catch {
            Write-Log "Erro ao enviar os dados para a API: $_"
        }
    } else {
        Write-Log "Arquivo CSV não encontrado. Certifique-se de que o comando foi executado corretamente."
    }
}

# Executa o comando para gerar o arquivo CSV
function Execute-Command {
    Write-Log "Executando UserAssistView.exe para gerar o CSV..."
    try {
        Start-Process -FilePath $executablePath -ArgumentList "/scomma $csvFilePath" -NoNewWindow -Wait
        Write-Log "Comando executado com sucesso, CSV gerado."
        Start-Sleep -Seconds 5
    } 
    catch {
        Write-Log "Erro ao executar o comando: $_"
        throw $_
    }
}
# Gera o CSV e envia os dados
Execute-Command
Process-And-Upload
