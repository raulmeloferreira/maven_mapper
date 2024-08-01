require 'csv'
require 'byebug'

# Caminho para o seu arquivo CSV
csv_file_path = 'seu_arquivo.csv'

# Hash para armazenar as contagens
counts = Hash.new(0)

# Ler o arquivo CSV
CSV.foreach(csv_file_path, headers: true, col_sep: ';') do |row|
  # Extrair os valores das colunas
  parent = row['PARENT']
  parent_group = row['PARENT GROUP']
  version = row['VERSION']

  # Incrementar a contagem para o trio (PARENT, PARENT GROUP, VERSION)
  counts[[parent, parent_group, version]] += 1
end
