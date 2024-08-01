require 'csv'

def print_help
  puts <<-HELP
Usage: ruby script.rb [options] <csv_file_path>
Options:
    --help                       Show this help message
Description:
    This script reads a CSV file and counts the occurrences of each (PARENT, PARENT GROUP, VERSION) trio.
Example:
    ruby script.rb /path/to/your_file.csv
  HELP
end

# Process command line arguments
if ARGV.include?('--help') || ARGV.empty?
  print_help
  exit 0
end

csv_file_path = ARGV[0]

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

# Ordenar os trios pela contagem em ordem decrescente
sorted_counts = counts.sort_by { |_, count| -count }

# Imprimir as contagens e calcular o total
total_count = 0
sorted_counts.each do |trio, count|
  puts "PARENT: #{trio[0]}, PARENT GROUP: #{trio[1]}, VERSION: #{trio[2]} - Count: #{count}"
  total_count += count
end

# Imprimir o total de contagens
puts "Total de contagens: #{total_count}"
