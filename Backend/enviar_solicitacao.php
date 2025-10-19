<?php
// Incluir os ficheiros do PHPMailer
use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;

// O require_once garante que os ficheiros são incluídos apenas uma vez
require_once 'PHPMailer/Exception.php';
require_once 'PHPMailer/PHPMailer.php';
require_once 'PHPMailer/SMTP.php';

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

$data = json_decode(file_get_contents("php://input"));


if (!isset($data->id_solicitante) || !isset($data->destino) || !isset($data->motivo)) {
    http_response_code(400);
    echo json_encode(["sucesso" => false, "mensagem" => "Dados essenciais incompletos."]);
    exit();
}


$id_solicitante = $data->id_solicitante;
$destino = $data->destino;
$tipos_json = json_encode($data->tipos_solicitacao ?? []);
$observacoes = $data->observacoes ?? '';
$tipo_vigencia = $data->tipo_vigencia ?? null;
$data_de_sql = !empty($data->data_de) ? DateTime::createFromFormat('d/m/Y', $data->data_de)->format('Y-m-d') : null;
$data_ate_sql = !empty($data->data_ate) ? DateTime::createFromFormat('d/m/Y', $data->data_ate)->format('Y-m-d') : null;
$periodos_json = json_encode($data->periodos ?? []);
$motivo = $data->motivo;

// --- BUSCA O NOME DO MÉDICO SOLICITANTE ---
$nome_solicitante = "Não identificado";
$stmt_user = $conn->prepare("SELECT nome FROM usuarios WHERE id = ?");
if($stmt_user) {
    $stmt_user->bind_param("i", $id_solicitante);
    $stmt_user->execute();
    $result_user = $stmt_user->get_result();
    if($user_row = $result_user->fetch_assoc()) {
        $nome_solicitante = $user_row['nome'];
    }
    $stmt_user->close();
}


// --- Inserção no Banco de Dados ---
$sql = "INSERT INTO solicitacoes (id_solicitante, destino, tipos_solicitacao, observacoes, tipo_vigencia, data_de, data_ate, periodos, motivo) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)";
$stmt = $conn->prepare($sql);
$stmt->bind_param("issssssss", $id_solicitante, $destino, $tipos_json, $observacoes, $tipo_vigencia, $data_de_sql, $data_ate_sql, $periodos_json, $motivo);

if ($stmt->execute()) {
    // Se a inserção foi bem-sucedida, envie o e-mail
    $mail = new PHPMailer(true);

    try {
        //Configurações do Servidor
        $mail->isSMTP();
        $mail->Host       = 'smtp.gmail.com';
        $mail->SMTPAuth   = true;
        // MUITO IMPORTANTE: Substitua pelos seus dados
        $mail->Username   = ''; // O seu endereço de e-mail do Gmail
        $mail->Password   = ''; // A sua SENHA DE APP de 16 caracteres , você precisa criar a senha de APP no gmail
        $mail->SMTPSecure = PHPMailer::ENCRYPTION_SMTPS;
        $mail->Port       = 465;
        $mail->CharSet    = 'UTF-8';

        //Remetente e Destinatário
        $mail->setFrom('teste@gmail.com', 'Sistema Hospital'); // Configure email que enviará
        // MUITO IMPORTANTE: Substitua pelo e-mail do gestor
        $mail->addAddress('', 'Gestão'); // o email que receberá os alertas

        //Conteúdo do E-mail
        $mail->isHTML(true);
        $mail->Subject = 'Nova Solicitação de Alteração de Agenda - ' . $nome_solicitante;
        $mail->Body    = "Olá,<br><br>Uma nova solicitação de alteração de agenda foi registada no sistema.<br><br>" .
                         "<b>Solicitante:</b> " . htmlspecialchars($nome_solicitante) . "<br>" .
                         "<b>Destino:</b> " . htmlspecialchars($destino) . "<br>" .
                         "<b>Motivo:</b> " . htmlspecialchars($motivo) . "<br>" .
                         "<b>Observações:</b> " . htmlspecialchars($observacoes) . "<br><br>" .
                         "Por favor, aceda ao painel do gestor para rever os detalhes e tomar uma ação.";
        $mail->AltBody = 'Uma nova solicitação de alteração de agenda foi registada no sistema. Solicitante: ' . $nome_solicitante . '. Por favor, aceda ao painel do gestor.';

        $mail->send();
        
        echo json_encode(["sucesso" => true, "mensagem" => "Solicitação enviada e notificação enviada para o gestor!"]);

    } catch (Exception $e) {
        // Se o e-mail falhar, a solicitação já foi salva. Retornamos um aviso.
        echo json_encode(["sucesso" => true, "mensagem" => "Solicitação enviada com sucesso, mas falha ao enviar o e-mail. Erro: {$mail->ErrorInfo}"]);
    }
    
} else {
    http_response_code(500);
    echo json_encode(["sucesso" => false, "mensagem" => "Erro ao enviar solicitação: " . $stmt->error]);
}

$stmt->close();
$conn->close();
?>

