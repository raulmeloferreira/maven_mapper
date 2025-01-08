require 'nokogiri'
require 'csv'
require 'logger'
require 'find'
require 'open3'

log = Logger.new(STDOUT)
log.level = Logger::DEBUG

def get_last_commit_date(file, log)
  begin
    # Executa o comando `git log` para obter a data do último commit
    git_command = "git log -1 --format=%cd -- #{file}"
    log.debug("Running command: #{git_command}")
    output, status = Open3.capture2(git_command)

    if status.success?
      commit_date = output.strip
      log.debug("Last commit date for #{file}: #{commit_date}")
      return commit_date
    else
      log.warn("Failed to get last commit date for #{file}. Command output: #{output}")
      return "N/A"
    end
  rescue => e
    log.error("Error while getting last commit date for #{file}: #{e.message}")
    return "N/A"
  end
end

def parse_pom(pom_file, log)
  begin
    log.info("Parsing file: #{pom_file}")
    doc = Nokogiri::XML(File.open(pom_file))
    doc.remove_namespaces!

    project_group_id = doc.at_xpath("//groupId")&.text || ""
    project_artifact_id = doc.at_xpath("//artifactId")&.text || ""
    project_version = doc.at_xpath("//version")&.text || ""

    if project_group_id.empty?
      project_group_id = doc.at_xpath("//parent/groupId")&.text || ""
    end

    if project_version.empty?
      project_version = doc.at_xpath("//parent/version")&.text || ""
    end

    dependencies = doc.xpath("//dependencies/dependency").map do |dep|
      dep_group_id = dep.at_xpath("groupId")&.text || ""
      dep_artifact_id = dep.at_xpath("artifactId")&.text || ""
      dep_version = dep.at_xpath("version")&.text || ""

      [dep_group_id, dep_artifact_id, dep_version]
    end

    dependencies.map do |dep_group_id, dep_artifact_id, dep_version|
      [project_group_id, project_artifact_id, project_version, dep_group_id, dep_artifact_id, dep_version]
    end
  rescue => e
    log.error("Error parsing file #{pom_file}: #{e.message}")
    []
  end
end

def process_directory(directory, output_file, log)
  log.info("Looking for pom.xml files in directory: #{directory}")

  pom_files = []
  Find.find(directory) do |path|
    pom_files << path if path.end_with?('pom.xml')
  end

  if pom_files.empty?
    log.warn("No pom.xml files found in directory: #{directory}")
    return
  else
    log.info("Found #{pom_files.length} pom.xml files.")
  end

  CSV.open(output_file, 'wb', write_headers: true, headers: [
    'Project Group ID', 'Project Artifact ID', 'Project Version', 
    'Dependency Group ID', 'Dependency Artifact ID', 'Dependency Version', 
    'Last Commit Date'
  ], col_sep: ';') do |csv|
    pom_files.each do |pom_file|
      last_commit_date = get_last_commit_date(pom_file, log)
      rows = parse_pom(pom_file, log)
      rows.each do |row|
        csv << row + [last_commit_date]
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
