-- Create schemas
CREATE SCHEMA IF NOT EXISTS products;
CREATE SCHEMA IF NOT EXISTS customers;
CREATE SCHEMA IF NOT EXISTS sales;

-- Products Schema

SET search_path = products;

-- Product catalog table
CREATE TABLE IF NOT EXISTS catalog
(
	id             SERIAL PRIMARY KEY,
	name           VARCHAR(100)   NOT NULL,
	description    TEXT           NOT NULL,
	category       TEXT           NOT NULL CHECK (category IN ('coffee', 'mug', 't-shirt')),
	price          NUMERIC(10, 2) NOT NULL CHECK (price > 0),
	stock_quantity INT            NOT NULL DEFAULT 0 CHECK (stock_quantity >= 0)
);

-- Product reviews table
CREATE TABLE IF NOT EXISTS reviews
(
	id          BIGSERIAL PRIMARY KEY,
	product_id  INT      NOT NULL,
	customer_id INT      NOT NULL,
	review      TEXT     NOT NULL,
	rank        SMALLINT NOT NULL CHECK (rank BETWEEN 1 AND 5)
);

-- Customers Schema

SET search_path = customers;

-- Customer accounts table
CREATE TABLE IF NOT EXISTS accounts
(
	id          SERIAL PRIMARY KEY,
	name        TEXT NOT NULL,
	email       TEXT NOT NULL UNIQUE,
	passwd_hash TEXT NOT NULL,
	created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	deleted     BOOLEAN   DEFAULT FALSE
);

-- Sales Schema

SET search_path = sales;

-- Orders table
CREATE TABLE IF NOT EXISTS orders
(
	id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
	customer_id  INT REFERENCES customers.accounts (id),
	order_date   TIMESTAMPTZ      DEFAULT CURRENT_TIMESTAMP,
	total_amount DECIMAL(10, 2)
);

-- Order items table
CREATE TABLE IF NOT EXISTS order_items
(
	order_id   UUID REFERENCES sales.orders (id),
	product_id INT REFERENCES products.catalog (id),
	quantity   INT CHECK (quantity > 0),
	price      DECIMAL(10, 2),
	PRIMARY KEY (order_id, product_id)
);

-- Foreign Keys

SET search_path = products;

ALTER TABLE reviews
	DROP CONSTRAINT IF EXISTS fk_review_product;

ALTER TABLE reviews
	ADD CONSTRAINT fk_review_product
		FOREIGN KEY (product_id) REFERENCES catalog (id) ON DELETE CASCADE;

ALTER TABLE reviews
	DROP CONSTRAINT IF EXISTS fk_review_customer;

ALTER TABLE reviews
	ADD CONSTRAINT fk_review_customer
		FOREIGN KEY (customer_id) REFERENCES customers.accounts (id) ON DELETE CASCADE;

-- Insert sample products
INSERT INTO products.catalog (name, description, category, price, stock_quantity)
VALUES ('Sunrise Blend',
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
        't-shirt', 19.99, 25)
ON CONFLICT DO NOTHING;

-- Insert sample customers
INSERT INTO customers.accounts (name, email, passwd_hash)
VALUES ('Alice Johnson', 'alice.johnson@example.com', '5f4dcc3b5aa765d61d8327deb882cf99'),
       ('Bob Smith', 'bob.smith@example.com', 'd8578edf8458ce06fbc5bb76a58c5ca4'),
       ('Charlie Brown', 'charlie.brown@example.com', '5f4dcc3b5aa765d61d8327deb882cf99')
ON CONFLICT DO NOTHING;

-- Verify inserts
SELECT id, name
FROM customers.accounts;
SELECT id, name
FROM products.catalog
WHERE name = 'Sunrise Brew Co. Mug';

-- Insert a review
INSERT INTO products.reviews (product_id, customer_id, review, rank)
VALUES (4, 1, 'This mug is perfect — sturdy, stylish, and keeps my coffee warm for a good while.', 5)
ON CONFLICT DO NOTHING;

--- Soft Deletion

-- Mark customer as deleted instead of hard delete
UPDATE customers.accounts
SET deleted = TRUE
WHERE id = 1;

SELECT *
FROM customers.accounts;

--Transactions

-- Implicit transaction: Update stock quantities
UPDATE products.catalog
SET stock_quantity = stock_quantity + 100
WHERE id = 1;

UPDATE products.catalog
SET stock_quantity = stock_quantity + 50
WHERE id = 1
   OR id = 3;

--- Explicit Transaction

BEGIN;

-- Create order for customer 2 (Bob Smith) since customer 1 is marked deleted
INSERT INTO sales.orders (customer_id, total_amount)
VALUES (2, 26.98)
RETURNING id AS order_id;

INSERT INTO sales.orders (id, customer_id, total_amount)
VALUES ('19a0cffc-8757-453c-a4d2-b554fdc08954', 2, 26.98);

INSERT INTO sales.order_items (order_id, product_id, quantity, price)
VALUES ('19a0cffc-8757-453c-a4d2-b554fdc08954', 1, 1, 16.99),
       ('19a0cffc-8757-453c-a4d2-b554fdc08954', 4, 1, 9.99);

UPDATE products.catalog
SET stock_quantity = stock_quantity - 1
WHERE id IN (1, 4);

COMMIT;

-- Order for Alice (customer 1) - placed before she was marked deleted
INSERT INTO sales.orders (id, customer_id, total_amount)
VALUES ('a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 1, 14.99),
       ('b2c3d4e5-f6a7-4b5c-9d0e-1f2a3b4c5d6e', 1, 29.98);

INSERT INTO sales.order_items (order_id, product_id, quantity, price)
VALUES ('a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', 1, 1, 14.99),
       ('b2c3d4e5-f6a7-4b5c-9d0e-1f2a3b4c5d6e', 2, 1, 16.99),
       ('b2c3d4e5-f6a7-4b5c-9d0e-1f2a3b4c5d6e', 3, 1, 13.99);

-- Order for Charlie (customer 3)
INSERT INTO sales.orders (id, customer_id, total_amount)
VALUES ('c3d4e5f6-a7b8-4c5d-0e1f-2a3b4c5d6e7f', 3, 19.99),
       ('d4e5f6a7-b8c9-4d5e-1f2a-3b4c5d6e7f8a', 3, 33.97);

INSERT INTO sales.order_items (order_id, product_id, quantity, price)
VALUES ('c3d4e5f6-a7b8-4c5d-0e1f-2a3b4c5d6e7f', 5, 1, 19.99),
       ('d4e5f6a7-b8c9-4d5e-1f2a-3b4c5d6e7f8a', 3, 1, 13.99),
       ('d4e5f6a7-b8c9-4d5e-1f2a-3b4c5d6e7f8a', 4, 2, 9.99)
ON CONFLICT (order_id, product_id) DO NOTHING;

--- MVCC

BEGIN;

SELECT catalog.stock_quantity
FROM products.catalog
WHERE id = 1;

UPDATE products.catalog
SET stock_quantity = stock_quantity - 1
WHERE id = 1;

COMMIT;

-- Joins

-- Top 3 customers by total orders
SELECT c.name,
       c.id,
       COUNT(*)            AS total_orders,
       SUM(o.total_amount) AS total_spent
FROM customers.accounts c
	     JOIN sales.orders o ON c.id = o.customer_id
GROUP BY c.id
ORDER BY total_orders DESC
LIMIT 3;

-- All orders with customer and product details
SELECT o.id                     AS order_id,
       o.order_date,
       c.name                   AS customer_name,
       c.email,
       p.name                   AS product_name,
       oi.quantity,
       oi.price,
       (oi.quantity * oi.price) AS line_total
FROM sales.orders o
	     JOIN customers.accounts c ON o.customer_id = c.id
	     JOIN sales.order_items oi ON o.id = oi.order_id
	     JOIN products.catalog p ON oi.product_id = p.id
ORDER BY o.order_date DESC, o.id;

-- Orders by category
SELECT p.category,
       COUNT(DISTINCT o.id)        AS order_count,
       SUM(oi.quantity)            AS total_items_sold,
       SUM(oi.quantity * oi.price) AS total_revenue
FROM sales.orders o
	     JOIN sales.order_items oi ON o.id = oi.order_id
	     JOIN products.catalog p ON oi.product_id = p.id
GROUP BY p.category
ORDER BY total_revenue DESC;

-- Customer purchase summary (excluding soft-deleted customers)
SELECT c.name,
       c.email,
       COUNT(o.id)         AS order_count,
       SUM(o.total_amount) AS lifetime_value,
       MAX(o.order_date)   AS last_order_date
FROM customers.accounts c
	     LEFT JOIN sales.orders o ON c.id = o.customer_id
WHERE c.deleted = FALSE
GROUP BY c.id
ORDER BY lifetime_value DESC NULLS LAST;

-- Customers with no orders
SELECT c.name
FROM customers.accounts c
	     LEFT JOIN sales.orders s ON c.id = s.customer_id
WHERE s.customer_id IS NULL;

-- Looking at product popularity
SELECT c.name,
       c.category,
       c.price,
       SUM(oi.quantity) AS total_sold
FROM products.catalog c
	     LEFT JOIN sales.order_items oi ON c.id = oi.product_id
GROUP BY c.id
ORDER BY total_sold DESC NULLS LAST, c.price DESC;

--- Functions and Triggers

