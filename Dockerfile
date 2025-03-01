# Usa uma imagem base oficial do Ubuntu compatível com ARM64
FROM ubuntu:22.04

# Instala dependências essenciais para Flutter
RUN apt-get update && apt-get install -y \
    curl \
    unzip \
    git \
    xz-utils \
    libglu1-mesa \
    && rm -rf /var/lib/apt/lists/*

# Adiciona um usuário não root para rodar o Flutter
RUN useradd -ms /bin/bash flutteruser

# Define diretório de trabalho para instalação do Flutter
WORKDIR /home/flutteruser

# Aumenta o buffer do Git para evitar falhas de rede
RUN git config --global http.postBuffer 524288000
RUN git config --global http.sslVersion tlsv1.2

# Faz um clone COMPLETO do Flutter
RUN git clone --branch stable https://github.com/flutter/flutter.git /home/flutteruser/flutter

# Garante que o repositório tenha todas as referências
RUN git -C /home/flutteruser/flutter fetch --all

# Ajusta permissões do Flutter antes de trocar para usuário não-root
RUN chown -R flutteruser:flutteruser /home/flutteruser/flutter

# Agora troca para o usuário não-root
USER flutteruser
WORKDIR /home/flutteruser

# Adiciona Flutter ao PATH
ENV PATH="/home/flutteruser/flutter/bin:$PATH"

# Configura o Flutter para rodar corretamente sem erro de permissões
RUN git config --global --add safe.directory /home/flutteruser/flutter

# Ajusta permissões do Flutter antes de rodar flutter doctor
RUN chmod -R 777 /home/flutteruser/flutter

# Agora podemos rodar o Flutter sem erros de arquitetura
RUN /home/flutteruser/flutter/bin/flutter doctor

# Executa flutter precache para evitar problemas
RUN flutter precache

# Define diretório de trabalho para o projeto
WORKDIR /home/flutteruser/app

# 🔹 Copia os arquivos do projeto diretamente com o dono correto
COPY --chown=flutteruser:flutteruser . .

# Instala as dependências do Flutter
RUN flutter pub get

# Expõe a porta do servidor web
EXPOSE 8080

# Comando para rodar a aplicação no navegador
CMD ["flutter", "run", "-d", "web-server", "--web-port", "8080"]