
# Maven Project Analyzer

Este script Ruby analisa todos os projetos Maven em um diretório especificado, extrai informações de cada arquivo `pom.xml` encontrado e as imprime em um formato estruturado.

## Requisitos

- Ruby
- Gem Nokogiri

## Instalação

1. Certifique-se de que você tem o Ruby instalado em seu sistema.
2. Instale a gem `nokogiri` se você ainda não a tiver:

   ```bash
   gem install nokogiri
   ```

## Uso

### Execução do Script

Para executar o script, use o seguinte comando:

```bash
ruby maven_mapper.rb [opções] <root_directory>
```

### Parâmetros

- `<root_directory>`: O diretório raiz onde o script irá procurar por projetos Maven (obrigatório).
- `--help`: Mostra a mensagem de ajuda.

### Exemplos

#### Executar o script

```bash
ruby maven_mapper.rb /path/to/directory
```

#### Mostrar a mensagem de ajuda

```bash
ruby maven_mapper.rb --help
```

## Saída

O script imprimirá informações sobre cada projeto Maven encontrado no seguinte formato:

```
<sigla>; <artifact_id>; <group_id>; <version>; <parent_artifact_id>; <parent_group_id>; <parent_version>; <git_url>
```

### Exemplo de Saída

```
project-sigla; my-artifact; com.example; 1.0.0; parent-artifact; com.parent; 2.0.0; https://gitlab.grupo/project.git
```

## Estrutura do Código

### Classes

- **ParentInfo**: Contém informações sobre o parent do projeto Maven.
- **ProjectInfo**: Contém informações sobre o projeto Maven.
- **MavenProject**: Extrai e armazena informações de um arquivo `pom.xml`.

### Funções

- **analyze_maven_projects(root_directory)**: Analisa todos os projetos Maven no diretório especificado.
- **print_help**: Imprime a mensagem de ajuda.

## Tratamento de Erros

O script captura e imprime erros ao processar arquivos `pom.xml` ou ao ler o arquivo de configuração do Git.

