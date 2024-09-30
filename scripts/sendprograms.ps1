# URL do arquivo ZIP e local para download
$url = "https://viniciusm23.sg-host.com/executaveis/assistview/userassistview.zip"
$destinationPath = "C:\Windows\tempinst\exec\userassistview"
$executablePath = "$destinationPath\UserAssistView.exe"
$csvFilePath = "$destinationPath\programs.csv"

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
    $logFile = "C:\Windows\tempinst\exec\log_execution.txt"
    
    if (Test-Path $logFile) {
        $executionNumber = Get-Content $logFile
        $executionNumber = [int]$executionNumber
        
        # Incrementa o número da execução ou reseta para 1 se já for 5
        if ($executionNumber -ge 5) {
            $executionNumber = 1
        } else {
            $executionNumber++
        }
    } else {
        $executionNumber = 1
    }
    
    # Salva o novo número da execução
    Set-Content -Path $logFile -Value $executionNumber
    return $executionNumber
}

# Função para verificar se o arquivo já existe e, caso contrário, baixar
function Check-And-Download {
    if (-Not (Test-Path $executablePath)) {
        Write-Host "UserAssistView.exe não encontrado. Baixando e descompactando..."
        
        # Baixa o arquivo ZIP
        $zipPath = "$destinationPath\userassistview.zip"
        Invoke-WebRequest -Uri $url -OutFile $zipPath
        
        # Descompacta o arquivo baixado
        Expand-Archive -Path $zipPath -DestinationPath $destinationPath -Force
        
        # Remove o arquivo ZIP após a extração
        Remove-Item $zipPath
        Write-Host "Arquivo baixado e descompactado com sucesso."
    } else {
        Write-Host "UserAssistView.exe já existe. Pulando download."
    }
}

# Função para executar o comando e gerar o CSV
function Execute-Command {
    Write-Host "Executando UserAssistView.exe para gerar o CSV..."
    $command = "$executablePath /scomma $csvFilePath"
    Invoke-Expression $command
    Start-Sleep -Seconds 5
}

# Função para ler o CSV, preparar os dados e enviar para a API
function Process-And-Upload {
    Write-Host "Processando o arquivo CSV..."
    
    if (Test-Path $csvFilePath) {
        $executionNumber = Get-ExecutionNumber
        $id_UserMqn = Get-IdUserMqn
        $hostname = [System.Net.Dns]::GetHostName()
        $username = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
        Write-Host "Execution Number $executionNumber"
        
        # Obtém o conteúdo do arquivo CSV
        $programs = Get-Content $csvFilePath
        
        # Conta o número de linhas e exibe no console
        $numLinhas = $programs.Length
        $counter = 1
        Write-Host "Programas Encontrados: $numLinhas"
        
        # Lista para armazenar os programas para envio em lote
        $programList = @()
        
        # Processa o CSV linha a linha
        $programs | ForEach-Object {
            Write-Host "Processando Programa $counter/$numLinhas"
            $counter += 1
            $fields = $_ -split ","
            $programData = [pscustomobject]@{
                Program      = [string]$fields[0]           # Program na posição 0
                indice       = [int]$fields[1]              # RunCount na posição 1
                count        = if ($fields[2] -ne "") { [string]$fields[2] } else { "N/A" }  # LastRunTime na posição 2
                GUID         = [string]$fields[3]           # GUID na posição 3
                User         = $username                    # Nome do usuário atual
                Hostname     = $hostname                    # Nome do hostname atual
                id_UserMqn   = $id_UserMqn                  # ID gerado em Base64
                id_execution = $executionNumber.ToString()  # Número da execução
                program_id = "$($fields[1])-$($executionNumber)"
            }
            
            # Adiciona o programa processado à lista
            $programList += $programData
        }

        # Converte o objeto para JSON
        $jsonBody = $programList | ConvertTo-Json

        # URL da API
        $apiUrl = "http://zabbix.wenz.com.br:8000/programs"#"http://127.0.0.1:8000/programs"

        # Envia os dados para a API em lote
        try {
            $response = Invoke-RestMethod -Uri $apiUrl -Method Post -Body $jsonBody -ContentType "application/json"
            Write-Host "Dados enviados com sucesso! Resposta: $response"
        }
        catch {
            Write-Host "Erro ao enviar os dados para a API: $_"
        }
    } else {
        Write-Host "Arquivo CSV não encontrado. Certifique-se de que o comando foi executado corretamente."
    }
}

# Verifica se o arquivo UserAssistView.exe existe ou baixa-o
Check-And-Download

# Executa o comando para gerar o arquivo CSV
Execute-Command

# Processa o CSV gerado e faz o upload para a API
Process-And-Upload
