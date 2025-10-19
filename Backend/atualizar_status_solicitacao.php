<?php
// Ativar a exibição de erros para depuração
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: *");
header("Content-Type: application/json; charset=UTF-8");

// --- Configuração do Banco de Dados ---
$db_host = "localhost";
$db_user = "root";
$db_pass = "";
$db_name = "hospital";

$conn = new mysqli($db_host, $db_user, $db_pass, $db_name);

if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(["sucesso" => false, "mensagem" => "Falha na conexão com o banco de dados."]);
    exit();
}

// Pega os dados enviados pelo Flutter (em formato JSON)
$data = json_decode(file_get_contents("php://input"));

// Validação dos dados recebidos
if (!isset($data->id) || !isset($data->status)) {
    http_response_code(400); // Bad Request
    echo json_encode(["sucesso" => false, "mensagem" => "Dados incompletos: 'id' e 'status' são obrigatórios."]);
    exit();
}

$id_solicitacao = $data->id;
$novo_status = $data->status;

// Valida se o status é um dos valores permitidos
if ($novo_status !== 'Aprovado' && $novo_status !== 'Recusado') {
    http_response_code(400);
    echo json_encode(["sucesso" => false, "mensagem" => "Status inválido."]);
    exit();
}

// --- Lógica para Atualizar o Status ---
$stmt = $conn->prepare("UPDATE solicitacoes SET status = ? WHERE id = ?");
if ($stmt === false) {
    http_response_code(500);
    echo json_encode(["sucesso" => false, "mensagem" => "Erro ao preparar a query: " . $conn->error]);
    exit();
}

$stmt->bind_param("si", $novo_status, $id_solicitacao);

if ($stmt->execute()) {
    echo json_encode(["sucesso" => true, "mensagem" => "Solicitação atualizada com sucesso!"]);
} else {
    http_response_code(500);
    echo json_encode(["sucesso" => false, "mensagem" => "Erro ao atualizar a solicitação: " . $stmt->error]);
}

$stmt->close();
$conn->close();
?>

