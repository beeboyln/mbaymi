-- Add notification_sent column to reminders table to track if notification was already sent
ALTER TABLE reminders ADD COLUMN notification_sent BOOLEAN DEFAULT FALSE;
