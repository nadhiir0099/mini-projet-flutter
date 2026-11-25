<?php
// login.php : Verifies user credentials
require 'config.php';

$input = json_input();
$username = trim($input['username'] ?? '');
$password = trim($input['password'] ?? '');

if ($username === '' || $password === '') {
    respond(['error' => 'Username and password are required'], 400);
}

$st = $pdo->prepare('SELECT id, username, budget FROM users WHERE username = ? AND password = ?');
$st->execute([$username, $password]);
$user = $st->fetch();

if (!$user) {
    respond(['error' => 'Invalid username or password'], 401);
}

respond([
    'id' => (int) $user['id'],
    'username' => $user['username'],
    'budget' => (float) $user['budget'],
]);
