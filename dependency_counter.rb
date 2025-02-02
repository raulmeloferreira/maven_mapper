require 'csv'
require 'logger'

# Configurando o logger para usar a saída padrão (STDOUT)
log = Logger.new(STDOUT)
log.level = Logger::DEBUG

def count_dependencies(csv_file, map_with_version, log)
  log.info("Reading CSV file: #{csv_file}")
  
  dependency_counts = Hash.new(0)

  begin
    CSV.foreach(csv_file, headers: true, col_sep: ';') do |row|
      # Pegando os últimos três campos de cada linha do CSV
      dep_group_id = row['Dependency Group ID']
      dep_artifact_id = row['Dependency Artifact ID']
      dep_version = row['Dependency Version']

      # Criando a chave para o mapeamento
      key = if map_with_version
              "#{dep_group_id}:#{dep_artifact_id}:#{dep_version}"
            else
              "#{dep_group_id}:#{dep_artifact_id}"
            end

      # Contabilizando as ocorrências
      dependency_counts[key] += 1
    end

    log.info("Finished reading CSV file: #{csv_file}")
  rescue => e
    log.error("Error reading CSV file #{csv_file}: #{e.message}")
    return {}
  end

  dependency_counts
end

def print_help
  puts "Usage: ruby dependency_counter.rb <csv_file> <v>"
  puts " - <csv_file>: The CSV file generated by the previous script."
  puts " - <v>: Optional. Pass 'v' if you want to map dependencies by version."
end

if ARGV.size < 1 || ARGV.size > 2
  print_help
else
  csv_file = ARGV[0]
  map_with_version = ARGV[1] == 'v'
  log.info("Starting process with CSV file: #{csv_file}, mapping with version: #{map_with_version}")

  dependency_counts = count_dependencies(csv_file, map_with_version, log)

  # Ordenando por número de ocorrências de forma decrescente
  sorted_dependencies = dependency_counts.sort_by { |key, count| -count }

  # Exibindo os resultados
  puts "Dependency Count Results (ordered by occurrences):"
  sorted_dependencies.each do |key, count|
    puts "#{key} -> #{count} occurrences"
  end

  log.info("Finished counting dependencies")
end
