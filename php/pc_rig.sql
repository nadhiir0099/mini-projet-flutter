-- Base de données pour PC Rig Builder
CREATE DATABASE IF NOT EXISTS pc_rig_db;
USE pc_rig_db;

CREATE TABLE IF NOT EXISTS parts (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  category VARCHAR(50) NOT NULL,
  price DECIMAL(10, 2) NOT NULL,
  notes TEXT
);
