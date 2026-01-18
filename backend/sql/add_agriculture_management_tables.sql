-- Add fields to crops table
ALTER TABLE crops
ADD COLUMN IF NOT EXISTS variety VARCHAR(100),
ADD COLUMN IF NOT EXISTS cycle_duration_days INTEGER,
ADD COLUMN IF NOT EXISTS objective VARCHAR(50) DEFAULT 'consumption';

-- Add fields to harvests table
ALTER TABLE harvests
ADD COLUMN IF NOT EXISTS destination VARCHAR(50),
ADD COLUMN IF NOT EXISTS sale_price DOUBLE PRECISION;

-- Create inputs table (intrants)
CREATE TABLE IF NOT EXISTS inputs (
    id SERIAL PRIMARY KEY,
    farm_id INTEGER NOT NULL REFERENCES farms(id),
    crop_id INTEGER NULL REFERENCES crops(id),
    input_type VARCHAR(50),
    name VARCHAR(150),
    quantity DOUBLE PRECISION,
    unit VARCHAR(50),
    applied_date TIMESTAMP WITH TIME ZONE DEFAULT now(),
    cost DOUBLE PRECISION,
    notes VARCHAR(1000),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Create finance transactions table
CREATE TABLE IF NOT EXISTS finance_transactions (
    id SERIAL PRIMARY KEY,
    farm_id INTEGER NOT NULL REFERENCES farms(id),
    crop_id INTEGER NULL REFERENCES crops(id),
    transaction_type VARCHAR(20) NOT NULL,
    category VARCHAR(100),
    amount DOUBLE PRECISION NOT NULL,
    transaction_date TIMESTAMP WITH TIME ZONE DEFAULT now(),
    notes VARCHAR(1000),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Create reminders table
CREATE TABLE IF NOT EXISTS reminders (
    id SERIAL PRIMARY KEY,
    farm_id INTEGER NOT NULL REFERENCES farms(id),
    crop_id INTEGER NULL REFERENCES crops(id),
    title VARCHAR(200) NOT NULL,
    description VARCHAR(1000),
    remind_at TIMESTAMP WITH TIME ZONE NOT NULL,
    repeat_rule VARCHAR(200),
    is_done BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);
