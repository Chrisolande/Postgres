-- Create schemas
CREATE SCHEMA IF NOT EXISTS products;
CREATE SCHEMA IF NOT EXISTS customers;
CREATE SCHEMA IF NOT EXISTS sales;

SET search_path = products;

-- Product catalog table
CREATE TABLE IF NOT EXISTS catalog (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT NOT NULL,
    category TEXT NOT NULL CHECK (category IN ('coffee', 'mug', 't-shirt')),
    price NUMERIC(10, 2) NOT NULL CHECK (price > 0),
    stock_quantity INT NOT NULL DEFAULT 0 CHECK (stock_quantity >= 0)
);

-- Product reviews table
CREATE TABLE IF NOT EXISTS reviews (
    id BIGSERIAL PRIMARY KEY,
    product_id INT NOT NULL,
    customer_id INT NOT NULL,
    review TEXT NOT NULL,
    rank SMALLINT NOT NULL CHECK (rank BETWEEN 1 AND 5)
);

-- Add foreign key constraints for reviews
ALTER TABLE reviews
    ADD CONSTRAINT fk_review_product
    FOREIGN KEY (product_id) REFERENCES catalog(id) ON DELETE CASCADE;

ALTER TABLE reviews
    ADD CONSTRAINT fk_review_customer
    FOREIGN KEY (customer_id) REFERENCES customers.accounts(id) ON DELETE CASCADE;


SET search_path = customers;

-- Customer accounts table
CREATE TABLE IF NOT EXISTS accounts (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    passwd_hash TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample products
INSERT INTO products.catalog (name, description, category, price, stock_quantity)
VALUES
    ('Sunrise Blend',
     'A smooth and balanced blend with notes of caramel and citrus.',
     'coffee', 14.99, 50),
    ('Midnight Roast',
     'A dark roast with rich flavors of chocolate and toasted nuts.',
     'coffee', 16.99, 40),
    ('Morning Glory',
     'A light roast with bright acidity and floral notes.',
     'coffee', 13.99, 30),
    ('Sunrise Brew Co. Mug',
     'A ceramic mug with the Sunrise Brew Co. logo.',
     'mug', 9.99, 100),
    ('Sunrise Brew Co. T-Shirt',
     'A soft cotton t-shirt with the Sunrise Brew Co. logo.',
     't-shirt', 19.99, 25);

-- Insert sample customers
INSERT INTO customers.accounts (name, email, passwd_hash)
VALUES
    ('Alice Johnson', 'alice.johnson@example.com', '5f4dcc3b5aa765d61d8327deb882cf99'),
    ('Bob Smith', 'bob.smith@example.com', 'd8578edf8458ce06fbc5bb76a58c5ca4'),
    ('Charlie Brown', 'charlie.brown@example.com', '5f4dcc3b5aa765d61d8327deb882cf99');

SELECT id, name FROM customers.accounts;