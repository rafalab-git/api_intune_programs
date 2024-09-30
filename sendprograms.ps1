# URL do arquivo ZIP e local para download
$url = "https://viniciusm23.sg-host.com/executaveis/assistview/userassistview.zip"
$destinationPath = "C:\Windows\tempinst\exec\userassistview"
$executablePath = "$destinationPath\UserAssistView.exe"
$csvFilePath = "$destinationPath\programs.csv"

# Função para verificar se o arquivo já existe
function Check-And-Download {
    # Verifica se o UserAssistView.exe já existe
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
}

# Função para ler o CSV, preparar os dados e enviar para a API
function Process-And-Upload {
    Write-Host "Processando o arquivo CSV..."
    
    if (Test-Path $csvFilePath) {
        $programs = Get-Content $csvFilePath | ForEach-Object {
            $fields = $_ -split ","
            [pscustomobject]@{
                Program      = [string]$fields[0]           # Program na posição 0
                Index        = [int]$fields[1]              # RunCount na posição 1
                Count        = if ($fields[2] -ne "") { [string]$fields[2] } else { "N/A" }  # LastRunTime na posição 2
                GUID         = [string]$fields[3]           # GUID na posição 3
                User         = [string]$env:USERNAME        # Nome do usuário atual
                Hostname     = [string](hostname)           # Nome do hostname atual
            }
        }

        # Converte o objeto para JSON
        $jsonBody = $programs | ConvertTo-Json

        # URL da API
        $apiUrl = "http://127.0.0.1:8000/programs"#"http://zabbix.wenz.com.br:8000/programs"

        # Envia os dados para a API
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
