<?php
// Simple single-file REST API for PC Rig Builder with MySQL
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json; charset=UTF-8");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

$host = "localhost";
$user = "root";
$pass = "";
$db   = "pc_rig_db";

$conn = new mysqli($host, $user, $pass);
if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(["error" => "MySQL Connection failed: " . $conn->connect_error]);
    exit;
}

// Auto-create database & table
$conn->query("CREATE DATABASE IF NOT EXISTS $db");
$conn->select_db($db);
$conn->query("
    CREATE TABLE IF NOT EXISTS parts (
      id INT AUTO_INCREMENT PRIMARY KEY,
      name VARCHAR(255) NOT NULL,
      category VARCHAR(50) NOT NULL,
      price DECIMAL(10, 2) NOT NULL,
      notes TEXT
    )
");

$method = $_SERVER['REQUEST_METHOD'];
$id = isset($_GET['id']) ? intval($_GET['id']) : null;
$input = json_decode(file_get_contents("php://input"), true);

switch ($method) {
    case 'GET':
        $result = $conn->query("SELECT * FROM parts ORDER BY id DESC");
        $parts = [];
        while ($row = $result->fetch_assoc()) {
            $row['id'] = intval($row['id']);
            $row['price'] = floatval($row['price']);
            $parts[] = $row;
        }
        echo json_encode($parts);
        break;

    case 'POST':
        $name = $conn->real_escape_string($input['name'] ?? '');
        $category = $conn->real_escape_string($input['category'] ?? '');
        $price = floatval($input['price'] ?? 0);
        $notes = $conn->real_escape_string($input['notes'] ?? '');

        $sql = "INSERT INTO parts (name, category, price, notes) VALUES ('$name', '$category', $price, '$notes')";
        if ($conn->query($sql)) {
            http_response_code(201);
            echo json_encode(["id" => $conn->insert_id, "name" => $name, "category" => $category, "price" => $price, "notes" => $notes]);
        } else {
            http_response_code(500);
            echo json_encode(["error" => $conn->error]);
        }
        break;

    case 'PUT':
        if (!$id) {
            http_response_code(400);
            echo json_encode(["error" => "Missing part id"]);
            break;
        }
        $name = $conn->real_escape_string($input['name'] ?? '');
        $category = $conn->real_escape_string($input['category'] ?? '');
        $price = floatval($input['price'] ?? 0);
        $notes = $conn->real_escape_string($input['notes'] ?? '');

        $sql = "UPDATE parts SET name='$name', category='$category', price=$price, notes='$notes' WHERE id=$id";
        if ($conn->query($sql)) {
            echo json_encode(["message" => "Updated successfully"]);
        } else {
            http_response_code(500);
            echo json_encode(["error" => $conn->error]);
        }
        break;

    case 'DELETE':
        if (!$id) {
            http_response_code(400);
            echo json_encode(["error" => "Missing part id"]);
            break;
        }
        $conn->query("DELETE FROM parts WHERE id=$id");
        echo json_encode(["message" => "Deleted successfully"]);
        break;
}

$conn->close();
?>
