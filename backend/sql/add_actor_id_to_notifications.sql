-- 🔔 Ajouter la colonne actor_id à la table notifications
ALTER TABLE notifications ADD COLUMN actor_id INTEGER;
ALTER TABLE notifications ADD CONSTRAINT fk_notifications_actor_id FOREIGN KEY (actor_id) REFERENCES users(id) ON DELETE SET NULL;
CREATE INDEX IF NOT EXISTS idx_notifications_actor_id ON notifications(actor_id);
