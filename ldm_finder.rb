#!/usr/bin/env ruby
require 'fileutils'

# Constante para a URL base do GitLab
GITLAB_URL_BASE = 'https://gitlab.grupo/'

# Método para extrair a sigla da URL do git
def extract_sigla(url)
  if url && url != 0
    sigla = url.gsub(GITLAB_URL_BASE, '')
    sigla = sigla.split('/').first
    sigla
  end
end

# Método para processar cada repositório
def process_repo(repo_dir, diretorio_destino)
  config_file = File.join(repo_dir, '.git', 'config')

  if File.exist?(config_file)
    # Lê o arquivo config e extrai a URL do git
    url = nil
    File.foreach(config_file) do |line|
      if line.strip.start_with?("url =")
        url = line.split("=").last.strip
        break
      end
    end

    # Extrai a sigla da URL
    sigla = extract_sigla(url)

    if sigla
      # Cria o subdiretório no diretório de destino com o nome da sigla
      destino_sigla = File.join(diretorio_destino, sigla)
      FileUtils.mkdir_p(destino_sigla)

      # Copia os arquivos .ldm para o subdiretório correspondente no destino
      Dir.glob("#{repo_dir}/**/*.ldm").each do |ldm_file|
        FileUtils.cp(ldm_file, destino_sigla)
      end
    end
  end
end

# Método para varrer os diretórios recursivamente
def scan_directories(diretorio_origem, diretorio_destino)
  Dir.glob("#{diretorio_origem}/**/.git").each do |git_dir|
    repo_dir = File.dirname(git_dir)
    process_repo(repo_dir, diretorio_destino)
  end
end

# Checando se os diretórios de origem e destino foram passados como parâmetros
if ARGV.length != 2
  puts "Uso: ruby ldm_finder.rb <diretório_origem> <diretório_destino>"
  exit
end

diretorio_origem = ARGV[0]
diretorio_destino = ARGV[1]

# Executa a varredura dos diretórios
scan_directories(diretorio_origem, diretorio_destino)

puts "Processamento concluído!"
