-- Migration: Add category and description columns to sales table
ALTER TABLE sales ADD COLUMN category VARCHAR(50) DEFAULT NULL;
ALTER TABLE sales ADD COLUMN description TEXT DEFAULT NULL;
