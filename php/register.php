<?php
// register.php : Creates a new user in MySQL
require 'config.php';

$input = json_input();
$username = trim($input['username'] ?? '');
$password = trim($input['password'] ?? '');

if (strlen($username) < 3 || strlen($password) < 4) {
    respond(['error' => 'Username (min 3 chars) and password (min 4 chars) are required'], 400);
}

// Check if username already exists
$check = $pdo->prepare('SELECT id FROM users WHERE username = ?');
$check->execute([$username]);
if ($check->fetch()) {
    respond(['error' => 'Username already taken'], 409);
}

// Insert new user
$st = $pdo->prepare('INSERT INTO users (username, password, budget) VALUES (?, ?, 0)');
$st->execute([$username, $password]);

$userId = (int) $pdo->lastInsertId();

respond([
    'id' => $userId,
    'username' => $username,
    'budget' => 0.0,
], 201);
