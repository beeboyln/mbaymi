# 🗄️ Guide des migrations : Notebook Database

**Configuration et exécution des migrations Alembic pour le système de cahiers**

---

## 📋 Prérequis

- ✅ PostgreSQL ou Neon installé et connecté
- ✅ Backend Python (`backend/`) configuré
- ✅ Alembic déjà initialisé (`alembic/` dossier existe)

---

## 🚀 Migration rapide (2 minutes)

### Étape 1: Générer avec autogenerate

```bash
cd backend

# Activer l'environnement virtuel
source venv/bin/activate  # Mac/Linux
# ou
.\venv\Scripts\activate   # Windows

# Générer la migration
alembic revision --autogenerate -m "Add notebook tables"
```

**Résultat:** Un nouveau fichier créé dans `backend/alembic/versions/`

---

### Étape 2: Vérifier le fichier généré

Ouvrir `backend/alembic/versions/XXX_add_notebook_tables.py`

**Vous devriez voir:**
```python
def upgrade():
    # Create tables
    op.create_table(
        'notebooks',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('title', sa.String(length=255), nullable=False),
        # ... autres colonnes
    )
    op.create_table('notebook_sections', ...)
    op.create_table('notebook_tags', ...)
    op.create_table('notebook_comments', ...)
    op.create_table('notebook_shares', ...)
    op.create_table('notebook_versions', ...)
    
    # Create relationships
    op.create_foreign_key('fk_notebook_farm', 'notebooks', ...)
    # ...

def downgrade():
    # Drop tables and constraints
    op.drop_table('notebook_versions')
    op.drop_table('notebook_shares')
    # ...
```

**✅ Si vous voyez tout cela:** C'est bon, continuez.

**❌ Si c'est vide:** Vérifier que les modèles sont importés dans `backend/app/models/__init__.py`

---

### Étape 3: Appliquer la migration

```bash
# Exécuter la migration
alembic upgrade head
```

**Résultat:** Tables créées dans PostgreSQL

---

### Étape 4: Vérifier la base de données

```bash
# Connexion à PostgreSQL
psql your_database_name

# Lister les tables
\dt

# Vous devriez voir:
# public | notebook_comments
# public | notebook_sections
# public | notebook_shares
# public | notebooks
# public | notebook_tags
# public | notebook_versions

# Quitter
\q
```

---

## 🔍 Configuration détaillée

### Structure Alembic

```
backend/
├── alembic/
│   ├── versions/
│   │   ├── 001_initial_schema.py
│   │   ├── 002_add_animals.py
│   │   └── 003_add_notebook_tables.py ← NOUVELLE
│   ├── env.py
│   ├── script.py.mako
│   └── alembic.ini
├── app/
│   ├── models/
│   │   ├── __init__.py
│   │   ├── user.py
│   │   ├── animals.py
│   │   └── notebook.py ← NOUVEAU
│   └── main.py
└── requirements.txt

```

### Configuration alembic.ini

**Vérifier que la chaîne de connexion est correcte :**

```ini
# Dans backend/alembic.ini

sqlalchemy.url = postgresql://user:password@localhost:5432/mbaymi_db
# ou pour Neon:
# sqlalchemy.url = postgresql://user:password@host:5432/database?sslmode=require
```

### Import des modèles

**Dans `backend/alembic/env.py`, s'assurer que tous les modèles sont importés :**

```python
from app.models import base, user, animals, notebook  # ← Ajouter notebook
```

### Base de données cible

**Vérifier dans `backend/app/models/__init__.py`:**

```python
from sqlalchemy.orm import declarative_base

Base = declarative_base()

# Importer tous les modèles pour que Alembic les découvre
from .notebook import (
    ProjectNotebook,
    NotebookSection,
    NotebookTag,
    NotebookComment,
    NotebookShare,
    NotebookVersion,
)
```

---

## 🔄 Workflows courants

### Scénario 1: Première fois (fresh database)

```bash
# 1. Générer
alembic revision --autogenerate -m "Add notebook tables"

# 2. Vérifier le fichier généré
cat backend/alembic/versions/XXX_add_notebook_tables.py

# 3. Appliquer
alembic upgrade head

# 4. Vérifier
psql your_database -c "\dt"
```

---

### Scénario 2: Modifier les modèles (itération)

**Étape 1: Modifier le modèle**
```python
# Dans backend/app/models/notebook.py
class ProjectNotebook(Base):
    __tablename__ = "notebooks"
    
    # Ajouter une colonne
    status: Mapped[str] = mapped_column(String(50), default="draft")
```

**Étape 2: Générer la migration**
```bash
alembic revision --autogenerate -m "Add status column to notebooks"
```

**Étape 3: Appliquer**
```bash
alembic upgrade head
```

---

### Scénario 3: Rollback (annuler)

```bash
# Voir l'historique
alembic current
alembic history

# Revenir à une version antérieure
alembic downgrade -1  # Une version arrière

# Ou revenir à une version spécifique
alembic downgrade b56bd2b4b88
```

---

## 📊 Vérifier les migrations

### Vue complète de l'historique

```bash
alembic history --verbose
```

**Résultat:**
```
fb71ba45a56 -> 23cfc2c33c64 (head), Add notebook tables
<base> -> fb71ba45a56, Initial migration
```

---

### Vérifier la version actuelle

```bash
alembic current
```

**Résultat:**
```
INFO  [alembic.runtime.migration] Context impl PostgresqlImpl.
INFO  [alembic.runtime.migration] Will assume transactional DDL.
23cfc2c33c64 (head)
```

---

### Tables créées

```bash
# Lister avec descriptions
psql your_database -c "SELECT tablename FROM pg_tables WHERE schemaname='public';"

# Vérifier les colonnes
psql your_database -c "\d notebooks"
```

---

## 🐛 Dépannage

### "No migration script found"

**Cause:** Alembic n'a pas trouvé les modèles à migrer

**Solution:**
1. Vérifier l'import dans `backend/alembic/env.py`
2. Vérifier que `metadata = Base.metadata` est correct
3. Relancer: `alembic revision --autogenerate -m "..."`

---

### "Table already exists"

**Cause:** La table existe déjà dans la DB

**Solution A:** Si c'est la première fois
```bash
# Supprimer manuellement la table
psql your_database -c "DROP TABLE notebooks;"

# Puis réappliquer
alembic upgrade head
```

**Solution B:** Si ce n'est pas la première fois
```bash
# Ignorer et continuer
# Alembic marque comme "déjà appliqué"
alembic stamp head
```

---

### "Invalid database URL"

**Cause:** Chaîne de connexion incorrecte

**Vérifier:**
```bash
# Tester la connexion
psql postgresql://user:password@localhost:5432/mbaymi_db

# Si ça fonctionne, alembic.ini est peut-être incorrect
cat backend/alembic.ini | grep sqlalchemy.url
```

---

### "Column "xy" already exists"

**Cause:** Migration partiellement appliquée

**Solution:**
```bash
# Désinstaller complètement
alembic downgrade base

# Puis réappliquer
alembic upgrade head
```

---

## 📝 Best practices

### ✅ À FAIRE

1. **Générer auto avant de modifier**
   ```bash
   alembic revision --autogenerate -m "Clear description"
   ```

2. **Vérifier les migrations avant d'appliquer**
   ```bash
   cat backend/alembic/versions/XXX_*.py
   ```

3. **Exécuter en développement d'abord**
   ```bash
   # DB locale
   alembic upgrade head
   # Puis créer tickets de test avant prod
   ```

4. **Conserver l'historique**
   ```bash
   # Ne jamais supprimer les fichiers de versions
   # Alembic en a besoin pour le rollback
   ```

5. **Commenter les migrations complexes**
   ```python
   def upgrade():
       # Ajouter une colonne qui valide les statuts
       op.add_column('notebooks', 
           sa.Column('status', sa.String(50), nullable=False, server_default='draft'))
   ```

---

### ❌ À ÉVITER

1. **Ne pas modifier les vieux fichiers de migration**
   - Les migrations sont immuables une fois appliquées
   - Créer une nouvelle migration si vous devez corriger

2. **Ne pas utiliser Alembic en production sans test**
   - Toujours tester en staging d'abord
   - Faire un backup avant les grandes migrations

3. **Ne pas ignorer les erreurs d'autogenerate**
   - Alembic peut parfois générer du code incorrect
   - Vérifier le fichier généré avant d'appliquer

4. **Ne pas supprimer les colonnes légèrement**
   - La suppression de colonnes est dangereuse
   - Toujours faire un backup d'abord

---

## 🔐 Sécurité

### Variables d'environnement

**Ne pas commiter les credentials:**

```bash
# backend/.env (à ajouter à .gitignore)
DATABASE_URL=postgresql://user:password@localhost/mbaymi

# Dans alembic.ini
sqlalchemy.url = driver://%(DB_USER)s:%(DB_PASSWORD)s@%(DB_HOST)s/%(DB_NAME)s
```

### Backup avant migration

```bash
# Backup PostgreSQL
pg_dump your_database > backup_$(date +%Y%m%d_%H%M%S).sql

# Puis migrer
alembic upgrade head

# En cas de problème, restore
psql your_database < backup.sql
```

---

## 📚 Ressources

- [Alembic Documentation](https://alembic.sqlalchemy.org/)
- [SQLAlchemy ORM](https://docs.sqlalchemy.org/en/20/orm/)
- [PostgreSQL documentation](https://www.postgresql.org/docs/)

---

## ✅ Checklist post-migration

- [ ] Migration générée avec autogenerate
- [ ] Fichier de migration vérifié
- [ ] `alembic upgrade head` réussi
- [ ] Tables visibles dans psql
- [ ] Colonnes correctes avec les bons types
- [ ] Relations (foreign keys) créées
- [ ] Indexes créés (si applicable)
- [ ] Backend redémarré
- [ ] Tests de l'API réussis

---

## 🎯 Commandes récapitulatives

```bash
# Générer
alembic revision --autogenerate -m "Description"

# Appliquer
alembic upgrade head

# Annuler la dernière
alembic downgrade -1

# Voir l'historique
alembic history

# Voir la version actuelle
alembic current

# Réinitialiser complètement
alembic downgrade base
alembic upgrade head
```

---

**Statut:** ✅ Migrations prêtes pour Notebook system  
**Dernière mise à jour:** 2024
