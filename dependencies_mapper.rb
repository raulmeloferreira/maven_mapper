require 'nokogiri'
require 'csv'
require 'logger'
require 'find'

# Configurando o logger para usar a saída padrão (STDOUT)
log = Logger.new(STDOUT)
log.level = Logger::DEBUG

def parse_pom(pom_file, log)
  begin
    log.info("Parsing file: #{pom_file}")
    doc = Nokogiri::XML(File.open(pom_file))
    
    # Removendo namespaces para facilitar a navegação no XML
    doc.remove_namespaces!

    # Extraindo o groupId, artifactId, e version do projeto ou do parent
    project_group_id = doc.at_xpath("//groupId") ? doc.at_xpath("//groupId").text : ""
    log.debug("Project groupId: #{project_group_id}")

    project_artifact_id = doc.at_xpath("//artifactId") ? doc.at_xpath("//artifactId").text : ""
    log.debug("Project artifactId: #{project_artifact_id}")

    project_version = doc.at_xpath("//version") ? doc.at_xpath("//version").text : ""
    log.debug("Project version: #{project_version}")

    # Verificando se o projeto usa um parent para herdar groupId e version
    if project_group_id.empty?
      project_group_id = doc.at_xpath("//parent/groupId") ? doc.at_xpath("//parent/groupId").text : ""
      log.debug("Inherited groupId from parent: #{project_group_id}")
    end

    if project_version.empty?
      project_version = doc.at_xpath("//parent/version") ? doc.at_xpath("//parent/version").text : ""
      log.debug("Inherited version from parent: #{project_version}")
    end

    # Extraindo dependências
    dependencies = doc.xpath("//dependencies/dependency").map do |dep|
      dep_group_id = dep.at_xpath("groupId") ? dep.at_xpath("groupId").text : ""
      dep_artifact_id = dep.at_xpath("artifactId") ? dep.at_xpath("artifactId").text : ""
      dep_version = dep.at_xpath("version") ? dep.at_xpath("version").text : ""

      log.debug("Found dependency - groupId: #{dep_group_id}, artifactId: #{dep_artifact_id}, version: #{dep_version}")

      [dep_group_id, dep_artifact_id, dep_version]
    end

    log.info("Finished parsing file: #{pom_file}")

    dependencies.map do |dep_group_id, dep_artifact_id, dep_version|
      [project_group_id, project_artifact_id, project_version, dep_group_id, dep_artifact_id, dep_version]
    end

  rescue => e
    log.error("Error parsing file #{pom_file}: #{e.message}")
    return []
  end
end

def process_directory(directory, output_file, log)
  log.info("Looking for pom.xml files in directory: #{directory}")

  # Usando Find.find para percorrer todos os arquivos e diretórios, incluindo os ocultos
  pom_files = []
  Find.find(directory) do |path|
    pom_files << path if path.end_with?('pom.xml')
  end

  if pom_files.empty?
    log.warn("No pom.xml files found in directory: #{directory}")
  else
    log.info("Found #{pom_files.length} pom.xml files.")
  end

  # Usando ";" como delimitador
  CSV.open(output_file, 'wb', write_headers: true, headers: ['Project Group ID', 'Project Artifact ID', 'Project Version', 'Dependency Group ID', 'Dependency Artifact ID', 'Dependency Version'], col_sep: ';') do |csv|
    pom_files.each do |pom_file|
      log.info("Processing file: #{pom_file}")
      rows = parse_pom(pom_file, log)
      if rows.empty?
        log.warn("No data extracted from: #{pom_file}")
      else
        rows.each do |row|
          csv << row unless row.compact.empty? # Evita linhas vazias
          log.debug("Wrote row to CSV: #{row}")
        end
      end
    end
  end
end

def print_help
  puts "Usage: ruby script.rb <directory> [output_file.csv]"
  puts " - <directory>: The root directory containing Maven project subdirectories."
  puts " - [output_file.csv]: Optional. Name of the output CSV file. Default is 'maven_dependencies.csv'."
end

if ARGV.size < 1 || ARGV.size > 2
  print_help
else
  directory = ARGV[0]
  output_file = ARGV[1] || 'maven_dependencies.csv'
  log.info("Starting process with directory: #{directory}, output file: #{output_file}")
  process_directory(directory, output_file, log)
  log.info("Finished processing")
end
