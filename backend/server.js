const express = require('express');
const mysql = require('mysql2');
const cors = require('cors');

const app = express();
const PORT = 3000;

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// MySQL connection
const rootDb = mysql.createConnection({
  host: 'localhost',
  user: 'root',
  password: '',
});

rootDb.connect((err) => {
  if (err) {
    console.error('MySQL connection error:', err.message);
    return;
  }
  console.log('Connected to MySQL server.');

  rootDb.query('CREATE DATABASE IF NOT EXISTS pc_rig_db', (err) => {
    if (err) return console.error('Database error:', err.message);

    rootDb.changeUser({ database: 'pc_rig_db' }, (err) => {
      if (err) return console.error('Change user error:', err.message);

      // Create users table
      rootDb.query(`
        CREATE TABLE IF NOT EXISTS users (
          id INT AUTO_INCREMENT PRIMARY KEY,
          username VARCHAR(50) NOT NULL UNIQUE,
          password VARCHAR(255) NOT NULL,
          budget DECIMAL(10, 2) DEFAULT 0,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
      `, (err) => {
        if (err) return console.error('Users table error:', err.message);
        console.log('Table "users" is ready.');
      });

      // Create parts table with user_id
      rootDb.query(`
        CREATE TABLE IF NOT EXISTS parts (
          id INT AUTO_INCREMENT PRIMARY KEY,
          user_id INT,
          name VARCHAR(255) NOT NULL,
          category VARCHAR(50) NOT NULL,
          price DECIMAL(10, 2) NOT NULL,
          notes TEXT,
          FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        )
      `, (err) => {
        if (err) return console.error('Parts table error:', err.message);
        console.log('Table "parts" is ready.');

        // Add user_id column if table already existed without it
        rootDb.query(`
          SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS
          WHERE TABLE_SCHEMA = 'pc_rig_db' AND TABLE_NAME = 'parts' AND COLUMN_NAME = 'user_id'
        `, (err, rows) => {
          if (!err && rows.length === 0) {
            rootDb.query('ALTER TABLE parts ADD COLUMN user_id INT DEFAULT NULL', (err) => {
              if (err) console.error('Alter table error:', err.message);
              else console.log('Added user_id column to parts table.');
            });
          }
        });
      });

      console.log('MySQL Database "pc_rig_db" is ready.');
    });
  });
});

// ─── Auth endpoints ──────────────────────────────────────────────────────────

// Register
app.post('/api/register', (req, res) => {
  const { username, password } = req.body;
  if (!username || !password) {
    return res.status(400).json({ error: 'Username and password are required' });
  }
  if (username.length < 3) {
    return res.status(400).json({ error: 'Username must be at least 3 characters' });
  }
  if (password.length < 4) {
    return res.status(400).json({ error: 'Password must be at least 4 characters' });
  }

  rootDb.query('INSERT INTO users (username, password) VALUES (?, ?)',
    [username.trim(), password],
    (err, result) => {
      if (err) {
        if (err.code === 'ER_DUP_ENTRY') {
          return res.status(409).json({ error: 'Username already taken' });
        }
        return res.status(500).json({ error: err.message });
      }
      res.status(201).json({
        id: result.insertId,
        username: username.trim(),
        budget: 0,
      });
    }
  );
});

// Login
app.post('/api/login', (req, res) => {
  const { username, password } = req.body;
  if (!username || !password) {
    return res.status(400).json({ error: 'Username and password are required' });
  }

  rootDb.query('SELECT id, username, budget FROM users WHERE username = ? AND password = ?',
    [username.trim(), password],
    (err, rows) => {
      if (err) return res.status(500).json({ error: err.message });
      if (rows.length === 0) {
        return res.status(401).json({ error: 'Invalid username or password' });
      }
      const user = rows[0];
      res.json({
        id: user.id,
        username: user.username,
        budget: parseFloat(user.budget) || 0,
      });
    }
  );
});

// ─── Budget endpoints ────────────────────────────────────────────────────────

// Get budget
app.get('/api/budget', (req, res) => {
  const userId = req.query.user_id;
  if (!userId) return res.status(400).json({ error: 'user_id is required' });

  rootDb.query('SELECT budget FROM users WHERE id = ?', [userId], (err, rows) => {
    if (err) return res.status(500).json({ error: err.message });
    if (rows.length === 0) return res.status(404).json({ error: 'User not found' });
    res.json({ budget: parseFloat(rows[0].budget) || 0 });
  });
});

// Update budget
app.post('/api/budget', (req, res) => {
  const { user_id, budget } = req.body;
  if (!user_id || budget == null) {
    return res.status(400).json({ error: 'user_id and budget are required' });
  }

  rootDb.query('UPDATE users SET budget = ? WHERE id = ?',
    [parseFloat(budget), user_id],
    (err) => {
      if (err) return res.status(500).json({ error: err.message });
      res.json({ message: 'Budget updated', budget: parseFloat(budget) });
    }
  );
});

// ─── Parts endpoints (now user-scoped) ───────────────────────────────────────

// Get parts for a user
const handleGetParts = (req, res) => {
  const userId = req.query.user_id;
  const sql = userId
    ? 'SELECT * FROM parts WHERE user_id = ? ORDER BY id DESC'
    : 'SELECT * FROM parts ORDER BY id DESC';
  const params = userId ? [userId] : [];

  rootDb.query(sql, params, (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    const formatted = results.map((row) => ({
      ...row,
      price: parseFloat(row.price),
    }));
    res.json(formatted);
  });
};

app.get(['/api/parts', '/api/get_items.php'], handleGetParts);

// Add part
app.post(['/api/parts', '/api/add_item.php'], (req, res) => {
  const { name, category, price, notes, user_id } = req.body;
  if (!name || !category || price == null) {
    return res.status(400).json({ error: 'Name, category, and price are required' });
  }

  const sql = 'INSERT INTO parts (user_id, name, category, price, notes) VALUES (?, ?, ?, ?, ?)';
  rootDb.query(sql, [user_id || null, name, category, parseFloat(price), notes || ''], (err, result) => {
    if (err) return res.status(500).json({ error: err.message });
    res.status(201).json({
      id: result.insertId,
      user_id: user_id || null,
      name,
      category,
      price: parseFloat(price),
      notes: notes || '',
    });
  });
});

// Edit part
const handleEdit = (req, res) => {
  const id = req.params.id || req.body.id;
  const { name, category, price, notes } = req.body;
  const sql = 'UPDATE parts SET name = ?, category = ?, price = ?, notes = ? WHERE id = ?';
  rootDb.query(sql, [name, category, parseFloat(price), notes || '', id], (err) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ message: 'Part updated successfully' });
  });
};
app.put('/api/parts/:id', handleEdit);
app.post('/api/edit_item.php', handleEdit);

// Delete part
const handleDelete = (req, res) => {
  const id = req.params.id || req.body.id || req.query.id;
  rootDb.query('DELETE FROM parts WHERE id = ?', [id], (err) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ message: 'Part deleted successfully' });
  });
};
app.delete('/api/parts/:id', handleDelete);
app.post('/api/delete_item.php', handleDelete);

app.listen(PORT, () => {
  console.log(`Backend API running on http://localhost:${PORT}`);
});
