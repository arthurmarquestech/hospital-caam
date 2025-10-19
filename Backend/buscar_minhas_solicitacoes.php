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

// --- CORREÇÃO: Ler os dados a partir do corpo da requisição (POST) ---
$data = json_decode(file_get_contents("php://input"));

if (!isset($data->id_solicitante)) {
    http_response_code(400); // Bad Request
    echo json_encode(["sucesso" => false, "mensagem" => "ID do solicitante não fornecido."]);
    exit();
}

$id_solicitante = $data->id_solicitante;

// --- Lógica para Buscar Solicitações ---
$stmt = $conn->prepare("SELECT * FROM solicitacoes WHERE id_solicitante = ? ORDER BY data_criacao DESC");
if ($stmt === false) {
    http_response_code(500);
    echo json_encode(["sucesso" => false, "mensagem" => "Erro ao preparar a query: " . $conn->error]);
    exit();
}

$stmt->bind_param("i", $id_solicitante);
$stmt->execute();
$result = $stmt->get_result();

$solicitacoes = [];
if ($result->num_rows > 0) {
    while($row = $result->fetch_assoc()) {
        // As colunas que são JSON precisam ser decodificadas para o Flutter
        $row['tipos_solicitacao'] = json_decode($row['tipos_solicitacao']);
        $row['periodos'] = json_decode($row['periodos']);
        $solicitacoes[] = $row;
    }
}

echo json_encode(["sucesso" => true, "dados" => $solicitacoes]);

$stmt->close();
$conn->close();
?>

