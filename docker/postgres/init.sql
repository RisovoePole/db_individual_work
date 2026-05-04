CREATE TABLE IF NOT EXISTS users (
  id BIGSERIAL PRIMARY KEY,
  email VARCHAR(255) NOT NULL,
  password_hash TEXT NOT NULL
);

CREATE UNIQUE INDEX IF NOT EXISTS users_email_idx ON users (email);

INSERT INTO users (email, password_hash)
VALUES ('admin', '240be518fabd2724ddb6f04eeb4e4f97f4a3f76fd9a6e5f4150f1efb6f55f7b0')
ON CONFLICT (email) DO NOTHING;
