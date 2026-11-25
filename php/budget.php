<?php
// budget.php : Gets or updates user budget
require 'config.php';

$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'GET') {
    $userId = (int) ($_GET['user_id'] ?? 0);
    if ($userId <= 0) {
        respond(['error' => 'user_id is required'], 400);
    }

    $st = $pdo->prepare('SELECT budget FROM users WHERE id = ?');
    $st->execute([$userId]);
    $row = $st->fetch();

    if (!$row) {
        respond(['error' => 'User not found'], 404);
    }

    respond(['budget' => (float) $row['budget']]);
}

if ($method === 'POST') {
    $input = json_input();
    $userId = (int) ($input['user_id'] ?? 0);
    $budget = (float) ($input['budget'] ?? 0);

    if ($userId <= 0) {
        respond(['error' => 'user_id is required'], 400);
    }

    $st = $pdo->prepare('UPDATE users SET budget = ? WHERE id = ?');
    $st->execute([$budget, $userId]);

    respond(['success' => true, 'budget' => $budget]);
}
