<?php
// edit_item.php : Updates an existing component
require 'config.php';

$input = json_input();
$id       = (int) ($input['id'] ?? 0);
$name     = trim($input['name'] ?? '');
$category = trim($input['category'] ?? '');
$price    = (float) ($input['price'] ?? 0);
$notes    = trim($input['notes'] ?? '');

if ($id <= 0 || $name === '' || $price <= 0) {
    respond(['error' => 'ID, name, and valid price are required'], 400);
}

$st = $pdo->prepare('UPDATE parts SET name = ?, category = ?, price = ?, notes = ? WHERE id = ?');
$st->execute([$name, $category, $price, $notes, $id]);

respond(['success' => true, 'message' => 'Component updated successfully']);
