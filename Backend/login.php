<?php
// Permite que o app Flutter acesse a API (CORS) e define o tipo de conteúdo
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: *");
header("Content-Type: application/json; charset=UTF-8");

// --- Configuração do Banco de Dados ---
$db_host = "localhost";
$db_user = "root"; // Usuário padrão do XAMPP
$db_pass = "";     // Senha padrão do XAMPP é vazia
$db_name = "hospital"; // O nome do banco que você criou

// Tenta criar a conexão
try {
    $conn = new mysqli($db_host, $db_user, $db_pass, $db_name);
    // Verifica se houve erro na conexão
    if ($conn->connect_error) {
        throw new Exception("Falha na conexão com o banco de dados.");
    }
} catch (Exception $e) {
    // Retorna um erro em JSON se a conexão falhar
    http_response_code(500); // Erro interno do servidor
    echo json_encode(["sucesso" => false, "mensagem" => $e->getMessage()]);
    exit(); // Para a execução do script
}

// Pega os dados enviados pelo Flutter (em formato JSON)
$data = json_decode(file_get_contents("php://input"));

// Validação básica dos dados recebidos
if (!isset($data->usuario) || !isset($data->senha)) {
    http_response_code(400); // Requisição inválida
    echo json_encode(["sucesso" => false, "mensagem" => "Dados de usuário ou senha não fornecidos."]);
    exit();
}

$usuario = $data->usuario;
$senha = $data->senha;

// --- Lógica de Autenticação ---
// Usa prepared statements para evitar SQL Injection
$stmt = $conn->prepare("SELECT id, nome, senha, cargo FROM usuarios WHERE usuario = ?");
$stmt->bind_param("s", $usuario);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows > 0) {
    $user = $result->fetch_assoc();
    
    // Verifica se a senha enviada corresponde à senha criptografada no banco
    if (password_verify($senha, $user['senha'])) {
        // Sucesso no login
        echo json_encode([
            "sucesso" => true,
            "mensagem" => "Login bem-sucedido!",
            "dados_usuario" => [
                "id" => $user['id'],
                "nome" => $user['nome'],
                "cargo" => $user['cargo']
            ]
        ]);
    } else {
        // Senha incorreta
        echo json_encode(["sucesso" => false, "mensagem" => "Usuário ou senha inválidos."]);
    }
} else {
    // Usuário não encontrado
    echo json_encode(["sucesso" => false, "mensagem" => "Usuário ou senha inválidos."]);
}

$stmt->close();
$conn->close();
?>

