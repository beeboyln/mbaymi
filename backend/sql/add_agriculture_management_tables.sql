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
    reorder_threshold DOUBLE PRECISION DEFAULT 0,
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
    input_id INTEGER NULL REFERENCES inputs(id) ON DELETE SET NULL,
    activity_id INTEGER NULL REFERENCES activities(id) ON DELETE CASCADE,
    transaction_type VARCHAR(20) NOT NULL,
    category VARCHAR(100),
    amount DOUBLE PRECISION NOT NULL,
    transaction_date TIMESTAMP WITH TIME ZONE DEFAULT now(),
    notes VARCHAR(1000),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

ALTER TABLE inputs ADD COLUMN IF NOT EXISTS reorder_threshold DOUBLE PRECISION DEFAULT 0;
ALTER TABLE activities ADD COLUMN IF NOT EXISTS input_id INTEGER;
ALTER TABLE activities ADD COLUMN IF NOT EXISTS quantity_used DOUBLE PRECISION;
ALTER TABLE crop_problems ADD COLUMN IF NOT EXISTS input_id INTEGER;
ALTER TABLE crop_problems ADD COLUMN IF NOT EXISTS quantity_used DOUBLE PRECISION;
ALTER TABLE crop_problems ADD COLUMN IF NOT EXISTS finance_type VARCHAR(20);
ALTER TABLE crop_problems ADD COLUMN IF NOT EXISTS finance_amount DOUBLE PRECISION;
ALTER TABLE activities ADD COLUMN IF NOT EXISTS finance_type VARCHAR(20);
ALTER TABLE activities ADD COLUMN IF NOT EXISTS finance_amount DOUBLE PRECISION;

ALTER TABLE finance_transactions
ADD COLUMN IF NOT EXISTS input_id INTEGER;

ALTER TABLE finance_transactions ADD COLUMN IF NOT EXISTS activity_id INTEGER;
CREATE INDEX IF NOT EXISTS ix_finance_transactions_activity_id ON finance_transactions (activity_id);
ALTER TABLE finance_transactions ADD COLUMN IF NOT EXISTS problem_id INTEGER;
CREATE INDEX IF NOT EXISTS ix_finance_transactions_problem_id ON finance_transactions (problem_id);
CREATE INDEX IF NOT EXISTS ix_finance_transactions_input_id
ON finance_transactions (input_id);

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

ALTER TABLE notifications ADD COLUMN IF NOT EXISTS farm_id INTEGER;
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS crop_id INTEGER;
CREATE INDEX IF NOT EXISTS ix_notifications_farm_id ON notifications (farm_id);
CREATE INDEX IF NOT EXISTS ix_notifications_crop_id ON notifications (crop_id);
