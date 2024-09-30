# # Função para decodificar ROT13
# function Decode-ROT13 {
#     param (
#         [string]$InputText
#     )
    
#     $result = ($InputText.ToCharArray() | ForEach-Object {
#         $charCode = [int][char]$_
#         if (($charCode -ge 65 -and $charCode -le 90) -or ($charCode -ge 97 -and $charCode -le 122)) {
#             if ($charCode -ge 65 -and $charCode -le 90) {
#                 return [char](((($charCode - 65 + 13) % 26) + 65))
#             } elseif ($charCode -ge 97 -and $charCode -le 122) {
#                 return [char](((($charCode - 97 + 13) % 26) + 97))
#             }
#         }
#         return [char]$charCode
#     }) -join ''
    
#     return $result
# }

# # Função para ler e processar as entradas do UserAssist
# function Get-UserAssistData {
#     $userAssistPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\UserAssist\'
    
#     # Verificar se o caminho principal existe
#     if (!(Test-Path $userAssistPath)) {
#         Write-Warning "O diretório UserAssist não foi encontrado: $userAssistPath"
#         return
#     } else {
#         Write-Host "Diretório UserAssist encontrado: $userAssistPath"
#     }

#     # Obter todos os GUIDs do UserAssist
#     $guids = Get-ChildItem $userAssistPath

#     if ($guids.Count -eq 0) {
#         Write-Warning "Nenhuma subchave GUID foi encontrada no caminho: $userAssistPath"
#         return
#     } else {
#         Write-Host "Subchaves GUID encontradas: $($guids.PSChildName -join ', ')"
#     }

#     $results = @()

#     foreach ($guid in $guids) {
#         # Para cada GUID, obtenha as chaves sob 'Count'
#         $countKeyPath = "$userAssistPath$($guid.PSChildName)\Count"
        
#         if (Test-Path $countKeyPath) {
#             Write-Host "Chave encontrada: $countKeyPath"
#             $entries = Get-ItemProperty $countKeyPath
#         } else {
#             Write-Warning "Chave não encontrada: $countKeyPath"
#             continue
#         }

#         foreach ($entry in $entries.PSObject.Properties) {
#             # Decodificar o nome da entrada (usando ROT13)
#             $decodedName = Decode-ROT13 $entry.Name
#             Write-Host "Decodificando nome da entrada: $decodedName"

#             # Certifique-se de que o valor seja um array de bytes
#             if ($entry.Value -is [byte[]]) {
#                 $value = $entry.Value

#                 # Verificar se o valor tem pelo menos 16 bytes antes de processar
#                 if ($value.Length -ge 16) {
#                     try {
#                         # Converter os bytes corretos para as informações necessárias
#                         $runCount = [BitConverter]::ToInt32($value, 4)
#                         $lastExecutedFileTime = [BitConverter]::ToInt64($value, 12)

#                         # Converter o valor de FileTime para um objeto de data, lidando com exceções
#                         try {
#                             $lastExecutedDate = [DateTime]::FromFileTime($lastExecutedFileTime)
#                         } catch {
#                             Write-Warning "Erro ao converter FileTime para DateTime. FileTime inválido: $lastExecutedFileTime"
#                             continue
#                         }
                        
#                         # Filtrar se a data de execução for nos últimos 30 dias
#                         if ($lastExecutedDate -ge (Get-Date).AddDays(-30)) {
#                             $results += [pscustomobject]@{
#                                 Name = $decodedName
#                                 RunCount = $runCount
#                                 LastRunTime = $lastExecutedDate
#                             }
#                         }
#                     } catch {
#                         Write-Warning "Erro ao processar valores de execução: $_"
#                     }
#                 } else {
#                     Write-Warning "Valor de entrada menor que 16 bytes: $($entry.Name)"
#                 }
#             } else {
#                 Write-Warning "Valor não é um array de bytes ou é inválido: $($entry.Name)"
#             }
#         }
#     }

#     return $results
# }

# # Executar o script e exibir resultados
# $data = Get-UserAssistData

# if ($data.Count -gt 0) {
#     $data | Sort-Object LastRunTime -Descending | Format-Table Name, RunCount, LastRunTime -AutoSize
# } else {
#     Write-Host "Nenhum programa encontrado nos últimos 30 dias."
# }


# Função para decodificar ROT13
function Decode-ROT13 {
    param (
        [string]$InputText
    )
    
    $result = ($InputText.ToCharArray() | ForEach-Object {
        $charCode = [int][char]$_
        if (($charCode -ge 65 -and $charCode -le 90) -or ($charCode -ge 97 -and $charCode -le 122)) {
            if ($charCode -ge 65 -and $charCode -le 90) {
                return [char](((($charCode - 65 + 13) % 26) + 65))
            } elseif ($charCode -ge 97 -and $charCode -le 122) {
                return [char](((($charCode - 97 + 13) % 26) + 97))
            }
        }
        return [char]$charCode
    }) -join ''
    
    return $result
}

# Função para ler e processar as entradas do UserAssist
function Get-UserAssistData {
    $userAssistPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\UserAssist\'
    
    # Verificar se o caminho principal existe
    if (!(Test-Path $userAssistPath)) {
        Write-Warning "O diretório UserAssist não foi encontrado: $userAssistPath"
        return
    } else {
        Write-Host "Diretório UserAssist encontrado: $userAssistPath"
    }

    # Obter todos os GUIDs do UserAssist
    $guids = Get-ChildItem $userAssistPath

    if ($guids.Count -eq 0) {
        Write-Warning "Nenhuma subchave GUID foi encontrada no caminho: $userAssistPath"
        return
    } else {
        Write-Host "Subchaves GUID encontradas: $($guids.PSChildName -join ', ')"
    }

    $results = @()

    foreach ($guid in $guids) {
        # Para cada GUID, obtenha as chaves sob 'Count'
        $countKeyPath = "$userAssistPath$($guid.PSChildName)\Count"
        
        if (Test-Path $countKeyPath) {
            Write-Host "Chave encontrada: $countKeyPath"
            $entries = Get-ItemProperty $countKeyPath
        } else {
            Write-Warning "Chave não encontrada: $countKeyPath"
            continue
        }

        foreach ($entry in $entries.PSObject.Properties) {
            # Decodificar o nome da entrada (usando ROT13)
            $decodedName = Decode-ROT13 $entry.Name
            Write-Host "Decodificando nome da entrada: $decodedName"

            # Certifique-se de que o valor seja um array de bytes
            if ($entry.Value -is [byte[]]) {
                $value = $entry.Value

                # Verificar se o valor tem pelo menos 16 bytes antes de processar
                if ($value.Length -ge 16) {
                    try {
                        # Converter os bytes corretos para as informações necessárias
                        $runCount = [BitConverter]::ToInt32($value, 4)
                        $lastExecutedFileTime = [BitConverter]::ToInt64($value, 12)

                        # Converter o valor de FileTime para um objeto de data, lidando com exceções
                        try {
                            $lastExecutedDate = [DateTime]::FromFileTime($lastExecutedFileTime)
                        } catch {
                            Write-Warning "Erro ao converter FileTime para DateTime. FileTime inválido: $lastExecutedFileTime"
                            continue
                        }
                        
                        # Adicionar os resultados, independentemente da data
                        $results += [pscustomobject]@{
                            Name = $decodedName
                            RunCount = $runCount
                            LastRunTime = $lastExecutedDate
                        }
                    } catch {
                        Write-Warning "Erro ao processar valores de execução: $_"
                    }
                } else {
                    Write-Warning "Valor de entrada menor que 16 bytes: $($entry.Name)"
                }
            } else {
                Write-Warning "Valor não é um array de bytes ou é inválido: $($entry.Name)"
            }
        }
    }

    return $results
}

# Executar o script e exibir resultados
$data = Get-UserAssistData

if ($data.Count -gt 0) {
    $data | Sort-Object LastRunTime -Descending | Format-Table Name, RunCount, LastRunTime -AutoSize
} else {
    Write-Host "Nenhum programa foi encontrado."
}
