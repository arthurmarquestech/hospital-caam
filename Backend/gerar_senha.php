<?php
// Define a senha que queremos encriptar.
$senha_para_encriptar = '123456';

// Usa a função padrão e segura do PHP para gerar o hash da senha.
$hash = password_hash($senha_para_encriptar, PASSWORD_DEFAULT);

// Exibe o resultado de forma clara para que você possa copiar.
echo "<h3>Use o seguinte hash para a senha '123456':</h3>";
echo "<p><strong>Por favor, copie esta linha completa e cole na coluna 'senha' do seu banco de dados:</strong></p>";
// Usamos uma textarea para facilitar a seleção e cópia do hash completo.
echo "<textarea rows='3' cols='70' readonly>" . htmlspecialchars($hash) . "</textarea>";
?>

