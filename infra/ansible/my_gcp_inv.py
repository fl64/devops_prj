#!/usr/bin/env python3
import subprocess
import json
import sqlite3
import argparse

host = ''

gcp_instances = """ CREATE TABLE IF NOT EXISTS gcp_instances (
     id integer PRIMARY KEY,
     name text NOT NULL,
     ext_ip text NOT NULL,
     int_ip text NOT NULL,
     tags text NOT NULL  );
"""

def create_connection(db_file):
    try:
        connection = sqlite3.connect(db_file)
        return connection
    except Error as e:
        print(e)
    return None

def create_table(connection, create_table_sql):
    try:
        c = connection.cursor()
        c.execute(create_table_sql)
    except Error as e:
        print(e)

def sql_query(connection, sql):
    try:
        c = connection.cursor()
        c.execute(sql)
        return c
    except Error as e:
        print(e)

#Парсим аргументы
parser = argparse.ArgumentParser()
parser.add_argument('--host', dest="host")
parser.add_argument('--list', action='store_true')
try:
    results = parser.parse_args()
except:
    parser.print_help()
    sys.exit(0)

#Если хост указан в аргументах, то задаем значение переменной для поиска
if results.host:
    host = results.host

# Создаём sqlite DB в памяти и формируем таблицу для инстансов
connection = create_connection(':memory:')
create_table(connection, gcp_instances)

# Берем данные об инстансах через gcloud
gcp_json = subprocess.check_output('gcloud compute instances list --format=json', shell=True)
# Интерпретируем в json
data = json.loads(gcp_json)

# Парсим все это дело, чтобы потом было проще делать выборку
for instance in data:
    #print (instance["tags"]["items"])
    ins_tags = ', '.join(instance["tags"]["items"])
    ins_name = instance["name"]
    ins_ext_ip = instance["networkInterfaces"][0]["accessConfigs"][0]["natIP"]
    ins_int_ip = instance["networkInterfaces"][0]["networkIP"]

    insert_result_data = 'INSERT INTO gcp_instances ( name, ext_ip, int_ip, tags) VALUES (?, ?, ?, ?)'
    result = (ins_name, ins_ext_ip, ins_int_ip, ins_tags)
    try:
        c = connection.cursor()
        c.execute(insert_result_data, result)
    except Error as e:
        print(e)

# Задаем словарь
json_ins = {'_meta': {'hostvars': {}}}

# Сначала формируем группы хостов
sql = 'SELECT tags FROM gcp_instances WHERE name LIKE "%'+host+'%" GROUP BY tags '
for tag in sql_query(connection, sql):
    #print (tag)
    sql = 'SELECT name FROM gcp_instances WHERE (tags LIKE "%'+tag[0]+'%") and (name LIKE "%'+host+'%")'
    instances = []
    for instance in sql_query(connection, sql):
        instances.append(instance[0])
    json_ins[tag[0].split(", ")[1]] = {'hosts': instances} #Название группы формируется из второй части тега

# Затем в метаданные подставляем внешние адреса хостов
sql = 'SELECT * FROM gcp_instances WHERE (name LIKE "%'+host+'%")' #Не забыть указать группу тегов для фильтрации!
for row in sql_query(connection, sql):
    #print (row[1])
    json_ins['_meta']['hostvars'][row[1]] = {'ansible_host' : row[2], 'int_ip' : row[3]}


# Выводим json
print(json.dumps(json_ins, indent=4, sort_keys=True))
