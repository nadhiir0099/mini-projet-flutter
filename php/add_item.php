<?php
// add_item.php : Adds a new component to MySQL
require 'config.php';

$input = json_input();
$userId   = isset($input['user_id']) ? (int) $input['user_id'] : null;
$name     = trim($input['name'] ?? '');
$category = trim($input['category'] ?? '');
$price    = (float) ($input['price'] ?? 0);
$notes    = trim($input['notes'] ?? '');

if ($name === '' || $price <= 0) {
    respond(['error' => 'Name and valid price are required'], 400);
}

$st = $pdo->prepare('INSERT INTO parts (user_id, name, category, price, notes) VALUES (?, ?, ?, ?, ?)');
$st->execute([$userId, $name, $category, $price, $notes]);

respond([
    'success' => true,
    'id' => (int) $pdo->lastInsertId(),
    'user_id' => $userId,
    'name' => $name,
    'category' => $category,
    'price' => $price,
    'notes' => $notes,
], 201);
