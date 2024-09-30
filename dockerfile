# Usa a imagem oficial do Python como base
FROM python:3.9-slim

# Define o diretório de trabalho
WORKDIR /app

# Copia os arquivos de dependências para o contêiner
COPY requirements.txt .

# Executa o ls no diretório atual (raiz do contêiner) após copiar o arquivo de requirements
RUN ls -lah 

# Instala as dependências
RUN pip install --no-cache-dir -r requirements.txt

# Copia o conteúdo da aplicação para dentro do contêiner
COPY ./app /app

# Executa o ls novamente no diretório /app para listar o conteúdo após a cópia
RUN ls -lah /app

# Garante que a pasta /app tenha permissões de escrita
RUN chmod -R 777 /app

# Expõe a porta 8000 para o FastAPI
EXPOSE 8000

# Comando para iniciar a aplicação
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
