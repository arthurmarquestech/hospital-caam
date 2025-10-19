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
    http_response_code(500); // Internal Server Error
    echo json_encode(["sucesso" => false, "mensagem" => "Falha na conexão com o banco de dados: " . $conn->connect_error]);
    exit();
}

// --- Lógica para Buscar Solicitações ---
$sql = "SELECT 
            s.id, s.destino, s.tipos_solicitacao, s.observacoes, s.tipo_vigencia, 
            s.data_de, s.data_ate, s.periodos, s.motivo, s.data_criacao, s.status, 
            u.nome AS nome_solicitante 
        FROM 
            solicitacoes s 
        JOIN 
            usuarios u ON s.id_solicitante = u.id 
        ORDER BY 
            s.data_criacao DESC";

$result = $conn->query($sql);

// --- CORREÇÃO: Adicionar verificação de erro na query ---
if ($result === false) {
    http_response_code(500); // Internal Server Error
    echo json_encode(["sucesso" => false, "mensagem" => "Erro ao executar a consulta: " . $conn->error]);
    exit();
}

$solicitacoes = [];
if ($result->num_rows > 0) {
    while($row = $result->fetch_assoc()) {
        // As colunas que são JSON precisam ser decodificadas para o Flutter
        $row['tipos_solicitacao'] = json_decode($row['tipos_solicitacao']);
        $row['periodos'] = json_decode($row['periodos']);
        $solicitacoes[] = $row;
    }
}

// Retorna um objeto JSON com uma chave 'dados'
echo json_encode(["sucesso" => true, "dados" => $solicitacoes]);

$conn->close();
?>

