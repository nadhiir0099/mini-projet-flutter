<?php
// get_items.php : Returns components for the logged-in user
require 'config.php';

$userId = isset($_GET['user_id']) ? (int) $_GET['user_id'] : null;

if ($userId) {
    $st = $pdo->prepare('SELECT id, name, category, price, notes FROM parts WHERE user_id = ? ORDER BY id DESC');
    $st->execute([$userId]);
    $rows = $st->fetchAll();
} else {
    $rows = $pdo->query('SELECT id, name, category, price, notes FROM parts ORDER BY id DESC')->fetchAll();
}

foreach ($rows as &$r) {
    $r['id'] = (int) $r['id'];
    $r['price'] = (float) $r['price'];
}
unset($r);

respond($rows);
