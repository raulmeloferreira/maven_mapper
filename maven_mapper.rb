require 'nokogiri'
require 'find'

class MavenProject
  attr_accessor :parent, :project, :git_url

  def initialize(pom_file)
    @doc = Nokogiri::XML(File.open(pom_file))
    @doc.remove_namespaces! # Remove namespaces para simplificar a navegação no XML
    @parent = extract_parent_info
    @project = extract_project_info
    @git_url = extract_git_url(File.dirname(pom_file))
  end

  private

  def extract_parent_info
    parent_node = @doc.at_xpath('//parent')
    return nil unless parent_node

    {
      group_id: parent_node.at_xpath('groupId') ? parent_node.at_xpath('groupId').text : nil,
      artifact_id: parent_node.at_xpath('artifactId') ? parent_node.at_xpath('artifactId').text : nil,
      version: parent_node.at_xpath('version') ? parent_node.at_xpath('version').text : nil
    }
  end

  def extract_project_info
    {
      group_id: @doc.at_xpath('//project/groupId') ? @doc.at_xpath('//project/groupId').text : nil,
      artifact_id: @doc.at_xpath('//project/artifactId') ? @doc.at_xpath('//project/artifactId').text : nil,
      version: @doc.at_xpath('//project/version') ? @doc.at_xpath('//project/version').text : nil
    }
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
end

def analyze_maven_projects(root_directory)
  projects_info = []

  Find.find(root_directory) do |path|
    next unless File.directory?(path)
    pom_file = File.join(path, 'pom.xml')
    if File.exist?(pom_file)
      begin
        project = MavenProject.new(pom_file)
        projects_info << { path: path, parent: project.parent, project: project.project, git_url: project.git_url }
      rescue => e
        puts "Failed to process #{pom_file}: #{e.message}"
      end
    end
  end

  projects_info
end

# Use the function to analyze all Maven projects in a directory
root_directory = 'path/to/your/maven/projects'
projects_info = analyze_maven_projects(root_directory)

projects_info.each do |info|
  puts "Path: #{info[:path]}"
  puts "Parent Info: #{info[:parent]}"
  puts "Project Info: #{info[:project]}"
  puts "Git URL: #{info[:git_url]}"
  puts '---'
end
