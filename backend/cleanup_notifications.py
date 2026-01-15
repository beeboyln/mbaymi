#!/usr/bin/env python3
"""
Script pour nettoyer les vieilles notifications sans actor_id
"""
from app.database import SessionLocal
from app.models.notification import Notification

db = SessionLocal()

try:
    # Supprimer toutes les notifications avec actor_id=NULL
    count = db.query(Notification).filter(Notification.actor_id == None).delete()
    db.commit()
    print(f"✅ Deleted {count} notifications with NULL actor_id")
except Exception as e:
    print(f"❌ Error: {e}")
    db.rollback()
finally:
    db.close()
