require 'nokogiri'
require 'csv'

def parse_pom(pom_file)
  doc = Nokogiri::XML(File.open(pom_file))
  project_group_id = doc.at_xpath("//project/groupId")&.text || ""
  project_artifact_id = doc.at_xpath("//project/artifactId")&.text || ""
  project_version = doc.at_xpath("//project/version")&.text || ""

  dependencies = doc.xpath("//project/dependencies/dependency").map do |dep|
    dep_group_id = dep.at_xpath("groupId")&.text || ""
    dep_artifact_id = dep.at_xpath("artifactId")&.text || ""
    dep_version = dep.at_xpath("version")&.text || ""
    [dep_group_id, dep_artifact_id, dep_version]
  end

  dependencies.map do |dep_group_id, dep_artifact_id, dep_version|
    [project_group_id, project_artifact_id, project_version, dep_group_id, dep_artifact_id, dep_version]
  end
end

def process_directory(directory, output_file)
  CSV.open(output_file, 'wb', write_headers: true, headers: ['Project Group ID', 'Project Artifact ID', 'Project Version', 'Dependency Group ID', 'Dependency Artifact ID', 'Dependency Version']) do |csv|
    Dir.glob("#{directory}/**/pom.xml") do |pom_file|
      parse_pom(pom_file).each do |row|
        csv << row
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
  process_directory(directory, output_file)
end
