require 'nokogiri'
require 'find'

class ParentInfo
  attr_accessor :group_id, :artifact_id, :version

  def initialize(node)
    @group_id = node.at_xpath('groupId') ? node.at_xpath('groupId').text : nil
    @artifact_id = node.at_xpath('artifactId') ? node.at_xpath('artifactId').text : nil
    @version = node.at_xpath('version') ? node.at_xpath('version').text : nil
  end
end

class ProjectInfo
  attr_accessor :group_id, :artifact_id, :version, :java_version

  def initialize(doc)
    @group_id = doc.at_xpath('//project/groupId') ? doc.at_xpath('//project/groupId').text : nil
    @artifact_id = doc.at_xpath('//project/artifactId') ? doc.at_xpath('//project/artifactId').text : nil
    @version = doc.at_xpath('//project/version') ? doc.at_xpath('//project/version').text : nil
    @java_version = extract_java_version(doc)
  end

  private

  def extract_java_version(doc)
    java_version = doc.at_xpath('//properties/maven.compiler.source') ? doc.at_xpath('//properties/maven.compiler.source').text : nil
    return java_version if java_version

    java_version = doc.at_xpath('//build/plugins/plugin[artifactId="maven-compiler-plugin"]/configuration/source') ? doc.at_xpath('//build/plugins/plugin[artifactId="maven-compiler-plugin"]/configuration/source').text : nil
    java_version
  end
end

class MavenProject
  attr_accessor :parent, :project, :git_url, :sigla

  def initialize(pom_file)
    @doc = Nokogiri::XML(File.open(pom_file))
    @doc.remove_namespaces! # Remove namespaces para simplificar a navegação no XML
    @parent = extract_parent_info
    @project = extract_project_info
    @git_url = extract_git_url(File.dirname(pom_file))
    @sigla = extract_sigla(@git_url)
  end

  private

  def extract_parent_info
    parent_node = @doc.at_xpath('//parent')
    return nil unless parent_node

    ParentInfo.new(parent_node)
  end

  def extract_project_info
    ProjectInfo.new(@doc)
  end

  def extract_git_url(project_dir)
    git_config_file = File.join(project_dir, '.git', 'config')
    return nil unless File.exist?(git_config_file)

    begin
      File.open(git_config_file, 'r') do |file|
        file.each_line do |line|
          return $1 if line =~ /^\s*url\s*=\s*(.+)$/
        end
      end
    rescue => e
      puts "Failed to read #{git_config_file}: #{e.message}"
      return nil
    end
  end

  def extract_sigla(url)
    if url && url != 0
      sigla = url.gsub('https://gitlab.grupo/', '')
      sigla = sigla.split('/').first
      sigla
    end
  end
end

def analyze_maven_projects(root_directory)
  projects_info = []

  Find.find(root_directory) do |path|
    next unless File.directory?(path)
    pom_file = File.join(path, 'pom.xml')
    if File.exist?(pom_file)
      begin
        project = MavenProject.new(pom_file)
        projects_info << project
      rescue => e
        puts "Failed to process #{pom_file}: #{e.message}"
      end
    end
  end

  projects_info
end

def print_help
  puts <<-HELP
Usage: ruby maven_mapper.rb [options] <root_directory>
Options:
    --help                       Show this help message
Description:
    This script analyzes all Maven projects in the specified root directory.
    It extracts information from each 'pom.xml' file found and prints it in a structured format.
Example:
    ruby maven_mapper.rb /path/to/directory
  HELP
end

# Process command line arguments
if ARGV.include?('--help') || ARGV.empty?
  print_help
  exit 0
end

root_directory = ARGV[0]
projects_info = analyze_maven_projects(root_directory)

projects_info.each do |project|
  puts "#{project.sigla};#{project.project.artifact_id};#{project.project.group_id};#{project.project.version};#{project.parent&.artifact_id};#{project.parent&.group_id};#{project.parent&.version};#{project.git_url};#{project.project.java_version}"
end
