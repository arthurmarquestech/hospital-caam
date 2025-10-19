CAAM - Comunicado de Alteração de Agenda Médica
📋 Sobre o Projeto
O CAAM é uma aplicação web desenvolvida para otimizar a comunicação entre os médicos e a administração de um hospital no que diz respeito a alterações de agenda. A ferramenta permite que os médicos submetam solicitações de alteração de forma rápida e padronizada, logo após solicitação os gestores configurados recebem um e-mail com o aviso sobre a solicitação e os mesmos gestores(call-center) analisem e aprovem essas solicitações de forma centralizada e faça o seu devido ajuste nas agendas.
Este projeto foi construído com um Front-end em Flutter Web e um Back-end em PHP com MySQL, ideal para ser hospedado num servidor local (Intranet).

✨ Funcionalidades Principais
A aplicação possui dois perfis de utilizador distintos:
Perfil Médico
Login Seguro: Autenticação para acesso à plataforma.
Formulário de Solicitação: Interface intuitiva para submeter pedidos de alteração de agenda, incluindo:
Tipo de alteração (bloqueio, exclusão, troca, etc.).
Período da alteração (datas de início e fim).
Motivo e observações.
Acompanhamento de Solicitações: Uma tela dedicada ("Minhas Solicitações") onde o médico pode consultar o estado (Pendente, Aprovado, Recusado) de todos os seus pedidos.
Notificação de Sucesso: Feedback visual imediato após o envio de uma solicitação.
Perfil Gestor
Login Seguro: Acesso a um painel de administração.
Dashboard de Solicitações: Visualização centralizada de todas as solicitações pendentes de todos os médicos.
Aprovação/Recusa: Ações rápidas para aprovar ou recusar cada solicitação com um clique.
Atualização em Tempo Real: A lista é atualizada automaticamente após cada ação.
Notificação por E-mail: Envio automático de um e-mail para o gestor sempre que uma nova solicitação é criada.

🚀 Como Começar (Instalação e Configuração)
Siga estes passos para configurar o ambiente e executar o projeto num servidor local.
Pré-requisitos
Servidor Web Local: Um ambiente como XAMPP ou similar, com Apache e MySQL.
Flutter SDK: Certifique-se de que tem o Flutter instalado e configurado para desenvolvimento web.
Composer: Necessário para instalar as dependências do Back-end (PHPMailer).
1. Configuração do Back-end (API)
Copie os Ficheiros: Copie a pasta backend/api_caam para o diretório htdocs do seu XAMPP.
Instale o PHPMailer:
Abra um terminal dentro da pasta api_caam (C:\xampp\htdocs\api_caam).
Execute o comando: composer require phpmailer/phpmailer.
Configure as Credenciais:
Abra o ficheiro enviar_solicitacao.php e configure as suas credenciais do Gmail (e-mail e senha de app) e o e-mail do destinatário (gestor).
Verifique as credenciais do banco de dados ($db_user, $db_pass) em todos os ficheiros .php e ajuste se necessário.
2. Configuração do Banco de Dados
Crie a Base de Dados: No phpMyAdmin, crie uma nova base de dados chamada hospital_caam.
Execute o Script SQL: Selecione a base de dados hospital_caam, vá à aba SQL e cole o script abaixo para criar todas as tabelas e utilizadores iniciais.
-- Estrutura da tabela `usuarios`
CREATE TABLE `usuarios` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nome` varchar(255) NOT NULL,
  `usuario` varchar(100) NOT NULL,
  `senha` varchar(255) NOT NULL,
  `cargo` enum('Medico','Gestor') NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `usuario` (`usuario`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Estrutura da tabela `solicitacoes`
CREATE TABLE `solicitacoes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `id_solicitante` int(11) NOT NULL,
  `destino` varchar(100) NOT NULL,
  `tipos_solicitacao` text NOT NULL,
  `observacoes` text DEFAULT NULL,
  `tipo_vigencia` varchar(50) DEFAULT NULL,
  `data_de` date DEFAULT NULL,
  `data_ate` date DEFAULT NULL,
  `periodos` varchar(100) DEFAULT NULL,
  `motivo` varchar(100) DEFAULT NULL,
  `data_criacao` timestamp NOT NULL DEFAULT current_timestamp(),
  `status` enum('Pendente','Aprovado','Recusado') NOT NULL DEFAULT 'Pendente',
  PRIMARY KEY (`id`),
  KEY `id_solicitante` (`id_solicitante`),
  CONSTRAINT `solicitacoes_ibfk_1` FOREIGN KEY (`id_solicitante`) REFERENCES `usuarios` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Inserção de utilizadores de exemplo (senha padrão: 123456)
INSERT INTO `usuarios` (`nome`, `usuario`, `senha`, `cargo`) VALUES
('Dr. Junior Exemplo', 'junior.exemplo', '$2y$10$hTwByCC2Hu6NLAiNXq9TsO2CO08u6EPrFcoTQ9VLQUpZ0HCKKsVBS', 'Medico'),
('Gestora Exemplo', 'gestora.exemplo', '$2y$10$hTwByCC2Hu6NLAiNXq9TsO2CO08u6EPrFcoTQ9VLQUpZ0HCKKsVBS', 'Gestor');


3. Configuração do Front-end (Flutter)
Abra o Projeto: Abra a pasta frontend/projecthosl no seu editor de código (VS Code).
Instale as Dependências: No terminal, execute: flutter pub get.
Ajuste a URL da API:
Em todos os ficheiros .dart dentro da pasta lib/telas/, encontre a linha final url = Uri.parse('...');.
Certifique-se de que o endereço IP corresponde ao do seu servidor local (ex: http://10.82.0.8/api_caam/...).
Execute a Aplicação (Desenvolvimento):
Use a configuração de inicialização Flutter Web (No CORS) no VS Code e pressione F5.
Compile para Produção:
Para gerar os ficheiros para o servidor, execute: flutter build web --base-href /nome_da_pasta_no_servidor/.
Copie o conteúdo da pasta build/web para a pasta do seu projeto no servidor (ex: htdocs/projecthosl).
🛠️ Tecnologias Utilizadas
Front-end: Flutter
Back-end: PHP
Banco de Dados: MySQL
Servidor Local: XAMPP
Envio de E-mail: PHPMailer


A senha criptografada que você está vendo foi gerada através do gerar_senha.php.
