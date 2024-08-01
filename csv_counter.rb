require 'csv'

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

# Imprimir as contagens e calcular o total
total_count = 0
counts.each do |trio, count|
  puts "PARENT: #{trio[0]}, PARENT GROUP: #{trio[1]}, VERSION: #{trio[2]} - Count: #{count}"
  total_count += count
end

# Imprimir o total de contagens
puts "Total de contagens: #{total_count}"
