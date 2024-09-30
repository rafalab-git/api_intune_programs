from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List
import sqlite3
import os

app = FastAPI()

# Caminho para o banco de dados SQLite
DATABASE_URL = "/app/programs_data.db"

# Cria o banco de dados e a tabela se não existirem
def create_database():
    conn = sqlite3.connect(DATABASE_URL)
    cursor = conn.cursor()
    cursor.execute('''CREATE TABLE IF NOT EXISTS programs (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        program TEXT,
                        indice INTEGER,
                        count INTEGER,
                        guid TEXT,
                        user TEXT,
                        hostname TEXT,
                        id_UserMqn TEXT,
                        id_execution TEXT,
                        program_id TEXT UNIQUE
                    )''')
    conn.commit()
    conn.close()

create_database()

# Define a classe que irá receber o payload enviado via POST
class ProgramData(BaseModel):
    Program: str
    indice: int
    count: int
    GUID: str
    User: str
    Hostname: str
    id_UserMqn: str
    id_execution: str
    program_id: str

# Função para salvar dados no SQLite
def save_programs_to_db(programs: List[ProgramData]):
    conn = sqlite3.connect(DATABASE_URL)
    cursor = conn.cursor()
    
    for program in programs:
        cursor.execute('''
            INSERT OR REPLACE INTO programs (program, indice, count, guid, user, hostname, id_UserMqn, id_execution, program_id)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', (program.Program, program.indice, program.count, program.GUID, program.User, program.Hostname, program.id_UserMqn, program.id_execution, program.program_id))
    
    conn.commit()
    conn.close()

# Rota para receber os dados do CSV
@app.post("/programs")
def receive_programs(programs: List[ProgramData]):
    # Salva os dados no banco de dados SQLite
    save_programs_to_db(programs)
    return {"message": "Dados recebidos e armazenados no banco de dados com sucesso!"}

# Função para buscar dados no SQLite
def get_programs_from_db():
    conn = sqlite3.connect(DATABASE_URL)
    cursor = conn.cursor()
    
    cursor.execute('SELECT program, indice, count, guid, user, hostname, id_UserMqn, id_execution, program_id FROM programs')
    rows = cursor.fetchall()
    
    conn.close()
    return rows

# Rota para visualizar os dados armazenados (opcional)
@app.get("/programs")
def get_programs():
    programs = get_programs_from_db()
    
    if not programs:
        raise HTTPException(status_code=404, detail="Nenhum dado encontrado.")
    
    return [{"Program": row[0], "indice": row[1], "count": row[2], "GUID": row[3], "User": row[4], "Hostname": row[5], "id_UserMqn": row[6], "id_execution": row[7], "program_id":row[8]} for row in programs]

@app.get("/programs/by-indice/{indice}")
def get_programs_by_indice(indice: int):
    conn = sqlite3.connect(DATABASE_URL)
    cursor = conn.cursor()
    
    cursor.execute('SELECT * FROM programs WHERE indice = ?', (indice,))
    rows = cursor.fetchall()
    
    conn.close()
    
    if not rows:
        raise HTTPException(status_code=404, detail="Nenhum dado encontrado para o índice fornecido.")
    
    return [{"Program": row[0], "indice": row[1], "count": row[2], "GUID": row[3], "User": row[4], "Hostname": row[5], "id_UserMqn": row[6], "id_execution": row[7], "program_id":row[8]} for row in rows]


@app.get("/programs/by-guid/{guid}")
def get_programs_by_guid(guid: str):
    conn = sqlite3.connect(DATABASE_URL)
    cursor = conn.cursor()
    
    cursor.execute('SELECT * FROM programs WHERE guid = ?', (guid,))
    rows = cursor.fetchall()
    
    conn.close()
    
    if not rows:
        raise HTTPException(status_code=404, detail="Nenhum dado encontrado para o GUID fornecido.")
    
    return [{"Program": row[0], "indice": row[1], "count": row[2], "GUID": row[3], "User": row[4], "Hostname": row[5], "id_UserMqn": row[6], "id_execution": row[7], "program_id":row[8]} for row in rows]


@app.get("/programs/by-user-mqn/{id_user_mqn}")
def get_programs_by_user_mqn(id_user_mqn: str):
    conn = sqlite3.connect(DATABASE_URL)
    cursor = conn.cursor()
    
    cursor.execute('SELECT * FROM programs WHERE id_UserMqn = ?', (id_user_mqn,))
    rows = cursor.fetchall()
    
    conn.close()
    
    if not rows:
        raise HTTPException(status_code=404, detail="Nenhum dado encontrado para o id_UserMqn fornecido.")
    
    return [{"Program": row[0], "indice": row[1], "count": row[2], "GUID": row[3], "User": row[4], "Hostname": row[5], "id_UserMqn": row[6], "id_execution": row[7], "program_id":row[8]} for row in rows]



@app.get("/programs/by-execution/{id_execution}")
def get_programs_by_execution(id_execution: str):
    conn = sqlite3.connect(DATABASE_URL)
    cursor = conn.cursor()
    
    cursor.execute('SELECT * FROM programs WHERE id_execution = ?', (id_execution,))
    rows = cursor.fetchall()
    
    conn.close()
    
    if not rows:
        raise HTTPException(status_code=404, detail="Nenhum dado encontrado para o id_execution fornecido.")
    
    return [{"Program": row[0], "indice": row[1], "count": row[2], "GUID": row[3], "User": row[4], "Hostname": row[5], "id_UserMqn": row[6], "id_execution": row[7], "program_id":row[8]} for row in rows]


@app.get("/programs/by-program-id/{program_id}")
def get_programs_by_program_id(program_id: str):
    conn = sqlite3.connect(DATABASE_URL)
    cursor = conn.cursor()
    
    cursor.execute('SELECT * FROM programs WHERE program_id = ?', (program_id,))
    rows = cursor.fetchall()
    
    conn.close()
    
    if not rows:
        raise HTTPException(status_code=404, detail="Nenhum dado encontrado para o program_id fornecido.")
    
    return [{"Program": row[0], "indice": row[1], "count": row[2], "GUID": row[3], "User": row[4], "Hostname": row[5], "id_UserMqn": row[6], "id_execution": row[7], "program_id":row[8]} for row in rows]


@app.get("/programs/by-hostname/{hostname}")
def get_programs_by_hostname(hostname: str):
    conn = sqlite3.connect(DATABASE_URL)
    cursor = conn.cursor()
    
    cursor.execute('SELECT * FROM programs WHERE hostname = ?', (hostname,))
    rows = cursor.fetchall()
    
    conn.close()
    
    if not rows:
        raise HTTPException(status_code=404, detail="Nenhum dado encontrado para o hostname fornecido.")
    
    return [{"Program": row[0], "indice": row[1], "count": row[2], "GUID": row[3], "User": row[4], "Hostname": row[5], "id_UserMqn": row[6], "id_execution": row[7], "program_id":row[8]} for row in rows]


