<?php
// delete_item.php : Deletes a component from MySQL
require 'config.php';

$input = json_input();
$id = (int) ($input['id'] ?? $_GET['id'] ?? 0);

if ($id <= 0) {
    respond(['error' => 'Invalid component ID'], 400);
}

$st = $pdo->prepare('DELETE FROM parts WHERE id = ?');
$st->execute([$id]);

respond(['success' => true, 'message' => 'Component deleted successfully']);
