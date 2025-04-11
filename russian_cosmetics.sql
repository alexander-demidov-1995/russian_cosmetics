CREATE DATABASE otk_russian_cosmetics;

\c otk_russian_cosmetics

CREATE TABLE services (
    service_id SERIAL PRIMARY KEY,
    service_code VARCHAR(20) NOT NULL UNIQUE,
    service_name VARCHAR(100) NOT NULL,
    price DECIMAL(10, 2) NOT NULL CHECK (price >= 0),
    execution_time_hours INTEGER NOT NULL CHECK (execution_time_hours > 0),
    average_deviation DECIMAL(10, 2),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    archived_at TIMESTAMP,
    archived_by INTEGER
);

CREATE TABLE legal_entities (
    client_id SERIAL PRIMARY KEY,
    company_name VARCHAR(100) NOT NULL,
    address TEXT NOT NULL,
    inn VARCHAR(12) NOT NULL UNIQUE,
    bank_account VARCHAR(20),
    bik VARCHAR(9),
    director_name VARCHAR(100) NOT NULL,
    contact_person VARCHAR(100) NOT NULL,
    contact_phone VARCHAR(20) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    archived_at TIMESTAMP,
    archived_by INTEGER
);

CREATE TABLE individuals (
    client_id SERIAL PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    birth_date DATE,
    passport_series VARCHAR(4),
    passport_number VARCHAR(6),
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    archived_at TIMESTAMP,
    archived_by INTEGER
);

CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    client_id INTEGER NOT NULL,
    client_type VARCHAR(10) NOT NULL CHECK (client_type IN ('legal', 'individual')),
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    total_cost DECIMAL(10, 2) DEFAULT 0,
    status VARCHAR(20) NOT NULL CHECK (status IN ('new', 'in_progress', 'completed', 'cancelled')),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    archived_at TIMESTAMP,
    archived_by INTEGER,
    CONSTRAINT chk_archive CHECK (
        (archived_at IS NULL) OR 
        (archived_at IS NOT NULL AND NOT EXISTS (
            SELECT 1 FROM order_items 
            WHERE order_id = orders.order_id 
            AND status != 'completed'
        ))
    )
);

CREATE TABLE order_items (
    item_id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    service_id INTEGER NOT NULL REFERENCES services(service_id),
    status VARCHAR(20) NOT NULL CHECK (status IN ('pending', 'in_progress', 'completed', 'cancelled')),
    assigned_to INTEGER,
    completed_at TIMESTAMP,
    completed_by INTEGER,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE service_results (
    result_id SERIAL PRIMARY KEY,
    item_id INTEGER NOT NULL REFERENCES order_items(item_id),
    performed_by INTEGER NOT NULL,
    performed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    result_data JSONB,
    conclusion TEXT,
    is_approved BOOLEAN DEFAULT FALSE,
    approved_by INTEGER,
    approved_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE employees (
    employee_id SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    position VARCHAR(50) NOT NULL CHECK (position IN ('head', 'admin', 'lab_technician', 'manager', 'controller')),
    last_login TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    archived_at TIMESTAMP,
    archived_by INTEGER
);

CREATE TABLE employee_services (
    employee_service_id SERIAL PRIMARY KEY,
    employee_id INTEGER NOT NULL REFERENCES employees(employee_id),
    service_id INTEGER NOT NULL REFERENCES services(service_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (employee_id, service_id)
);

CREATE INDEX idx_orders_client ON orders(client_id, client_type);
CREATE INDEX idx_order_items_order ON order_items(order_id);
CREATE INDEX idx_order_items_service ON order_items(service_id);
CREATE INDEX idx_order_items_status ON order_items(status);
CREATE INDEX idx_service_results_item ON service_results(item_id);
CREATE INDEX idx_employee_services_employee ON employee_services(employee_id);
CREATE INDEX idx_employee_services_service ON employee_services(service_id);