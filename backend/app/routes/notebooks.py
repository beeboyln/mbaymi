from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import Optional, List
from datetime import datetime

from app.database import get_db
from app.models.notebook import (
    ProjectNotebook, NotebookSection, NotebookTag, NotebookComment, 
    NotebookShare, NotebookVersion
)
from app.models.farm import Farm
from app.models.user import User
from app.schemas.schemas import (
    ProjectNotebookCreate, ProjectNotebookUpdate, ProjectNotebookResponse,
    NotebookCommentCreate, NotebookVersionCreate, NotebookVersionResponse
)
from app.routes.auth import get_current_user_obj

router = APIRouter(prefix="/api/notebooks", tags=["Notebooks"])

# ═══════════════════════════════════════════════════════════════════════════
# CREATE NOTEBOOK
# ═══════════════════════════════════════════════════════════════════════════

@router.post("", response_model=ProjectNotebookResponse, status_code=201)
def create_notebook(
    notebook_data: ProjectNotebookCreate,
    current_user: User = Depends(get_current_user_obj),
    db: Session = Depends(get_db)
):
    """
    📝 Créer un nouveau cahier de projet
    
    - **title**: Titre du cahier (requis)
    - **description**: Description détaillée
    - **farm_id**: ID de la ferme (optionnel)
    - **category**: Catégorie (general, culture, elevage, finance, maintenance)
    - **tags**: Tags pour l'organisation
    - **is_public**: Rendre public ou privé
    """
    print(f'[NOTEBOOKS API] POST create_notebook called')
    print(f'[NOTEBOOKS API] User: {current_user.id}, Title: {notebook_data.title}')
    
    # Créer le notebook (pas de vérification farm - c'est juste une note personnelle)
    new_notebook = ProjectNotebook(
        title=notebook_data.title,
        description=notebook_data.description,
        farm_id=notebook_data.farm_id,
        created_by=current_user.id,
        category=notebook_data.category,
        is_public=notebook_data.is_public,
        sections=[s.model_dump() for s in (notebook_data.sections or [])]
    )
    
    print(f'[NOTEBOOKS API] Notebook created: {new_notebook.id=}, sections={len(new_notebook.sections)} sections')
    
    db.add(new_notebook)
    db.flush()
    
    # Ajouter les tags
    for tag in notebook_data.tags or []:
        tag_obj = NotebookTag(notebook_id=new_notebook.id, tag=tag)
        db.add(tag_obj)
    
    db.commit()
    db.refresh(new_notebook)
    
    print(f'[NOTEBOOKS API] ✅ Notebook saved to DB with ID: {new_notebook.id}')
    
    return new_notebook


# ═══════════════════════════════════════════════════════════════════════════
# READ NOTEBOOKS
# ═══════════════════════════════════════════════════════════════════════════

@router.get("", response_model=List[ProjectNotebookResponse])
def list_notebooks(
    farm_id: Optional[int] = Query(None),
    category: Optional[str] = Query(None),
    is_public: Optional[bool] = Query(None),
    current_user: User = Depends(get_current_user_obj),
    db: Session = Depends(get_db)
):
    """
    📚 Lister les cahiers avec filtres
    
    - **farm_id**: Filtrer par ferme
    - **category**: Filtrer par catégorie
    - **is_public**: Filtrer par visibilité
    """
    query = db.query(ProjectNotebook).filter(
        (ProjectNotebook.created_by == current_user.id) |
        (ProjectNotebook.shares.any(NotebookShare.user_id == current_user.id)) |
        (ProjectNotebook.is_public == True)
    )
    
    if farm_id:
        query = query.filter(ProjectNotebook.farm_id == farm_id)
    if category:
        query = query.filter(ProjectNotebook.category == category)
    if is_public is not None:
        query = query.filter(ProjectNotebook.is_public == is_public)
    
    return query.all()


@router.get("/farm/{farm_id}", response_model=List[ProjectNotebookResponse])
def get_notebooks_by_farm(
    farm_id: int,
    current_user: User = Depends(get_current_user_obj),
    db: Session = Depends(get_db)
):
    """
    📖 Récupérer tous les cahiers d'une ferme
    """
    farm = db.query(Farm).filter(Farm.id == farm_id, Farm.user_id == current_user.id).first()
    if not farm:
        raise HTTPException(status_code=404, detail="Farm not found")
    
    return db.query(ProjectNotebook).filter(ProjectNotebook.farm_id == farm_id).all()


@router.get("/{notebook_id}", response_model=ProjectNotebookResponse)
def get_notebook(
    notebook_id: int,
    current_user: User = Depends(get_current_user_obj),
    db: Session = Depends(get_db)
):
    """
    📄 Récupérer un cahier spécifique
    """
    notebook = db.query(ProjectNotebook).filter(ProjectNotebook.id == notebook_id).first()
    
    if not notebook:
        raise HTTPException(status_code=404, detail="Notebook not found")
    
    # Vérifier les permissions
    if not (notebook.created_by == current_user.id or 
            notebook.is_public or
            db.query(NotebookShare).filter(
                NotebookShare.notebook_id == notebook_id,
                NotebookShare.user_id == current_user.id
            ).first()):
        raise HTTPException(status_code=403, detail="Access denied")
    
    return notebook


# ═══════════════════════════════════════════════════════════════════════════
# UPDATE NOTEBOOK
# ═══════════════════════════════════════════════════════════════════════════

@router.put("/{notebook_id}", response_model=ProjectNotebookResponse)
def update_notebook(
    notebook_id: int,
    notebook_data: ProjectNotebookUpdate,
    current_user: User = Depends(get_current_user_obj),
    db: Session = Depends(get_db)
):
    """
    ✏️ Mettre à jour un cahier
    """
    notebook = db.query(ProjectNotebook).filter(ProjectNotebook.id == notebook_id).first()
    
    if not notebook:
        raise HTTPException(status_code=404, detail="Notebook not found")
    
    # Vérifier les permissions
    if notebook.created_by != current_user.id:
        raise HTTPException(status_code=403, detail="Only creator can edit")
    
    # Mettre à jour les champs
    if notebook_data.title:
        notebook.title = notebook_data.title
    if notebook_data.description is not None:
        notebook.description = notebook_data.description
    if notebook_data.category:
        notebook.category = notebook_data.category
    if notebook_data.sections:
        notebook.sections = [s.model_dump() for s in notebook_data.sections]
    if notebook_data.is_public is not None:
        notebook.is_public = notebook_data.is_public
    
    # Mettre à jour les tags
    if notebook_data.tags is not None:
        db.query(NotebookTag).filter(NotebookTag.notebook_id == notebook_id).delete()
        for tag in notebook_data.tags:
            tag_obj = NotebookTag(notebook_id=notebook_id, tag=tag)
            db.add(tag_obj)
    
    notebook.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(notebook)
    
    return notebook


# ═══════════════════════════════════════════════════════════════════════════
# DELETE NOTEBOOK
# ═══════════════════════════════════════════════════════════════════════════

@router.delete("/{notebook_id}")
def delete_notebook(
    notebook_id: int,
    current_user: User = Depends(get_current_user_obj),
    db: Session = Depends(get_db)
):
    """
    🗑️ Supprimer un cahier
    """
    notebook = db.query(ProjectNotebook).filter(ProjectNotebook.id == notebook_id).first()
    
    if not notebook:
        raise HTTPException(status_code=404, detail="Notebook not found")
    
    # Vérifier les permissions
    if notebook.created_by != current_user.id:
        raise HTTPException(status_code=403, detail="Only creator can delete")
    
    db.delete(notebook)
    db.commit()
    
    return {"message": "Notebook deleted successfully"}


# ═══════════════════════════════════════════════════════════════════════════
# COMMENTS
# ═══════════════════════════════════════════════════════════════════════════

@router.post("/{notebook_id}/comments")
def add_comment(
    notebook_id: int,
    comment_data: NotebookCommentCreate,
    current_user: User = Depends(get_current_user_obj),
    db: Session = Depends(get_db)
):
    """
    💬 Ajouter un commentaire
    """
    notebook = db.query(ProjectNotebook).filter(ProjectNotebook.id == notebook_id).first()
    if not notebook:
        raise HTTPException(status_code=404, detail="Notebook not found")
    
    comment = NotebookComment(
        notebook_id=notebook_id,
        user_id=current_user.id,
        text=comment_data.text
    )
    
    db.add(comment)
    db.commit()
    db.refresh(comment)
    
    return {
        "id": comment.id,
        "user_id": comment.user_id,
        "text": comment.text,
        "created_at": comment.created_at
    }


@router.delete("/{notebook_id}/comments/{comment_id}")
def delete_comment(
    notebook_id: int,
    comment_id: int,
    current_user: User = Depends(get_current_user_obj),
    db: Session = Depends(get_db)
):
    """
    ❌ Supprimer un commentaire
    """
    comment = db.query(NotebookComment).filter(
        NotebookComment.id == comment_id,
        NotebookComment.notebook_id == notebook_id
    ).first()
    
    if not comment:
        raise HTTPException(status_code=404, detail="Comment not found")
    
    # Vérifier les permissions
    if comment.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Can only delete own comments")
    
    db.delete(comment)
    db.commit()
    
    return {"message": "Comment deleted"}


# ═══════════════════════════════════════════════════════════════════════════
# SHARING
# ═══════════════════════════════════════════════════════════════════════════

@router.post("/{notebook_id}/share")
def share_notebook(
    notebook_id: int,
    share_data: dict,  # {"user_ids": [1, 2, 3]}
    current_user: User = Depends(get_current_user_obj),
    db: Session = Depends(get_db)
):
    """
    🤝 Partager un cahier avec d'autres utilisateurs
    """
    notebook = db.query(ProjectNotebook).filter(ProjectNotebook.id == notebook_id).first()
    
    if not notebook:
        raise HTTPException(status_code=404, detail="Notebook not found")
    
    # Vérifier les permissions
    if notebook.created_by != current_user.id:
        raise HTTPException(status_code=403, detail="Only creator can share")
    
    for user_id in share_data.get("user_ids", []):
        # Vérifier que l'utilisateur existe
        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            continue
        
        # Éviter les doublons
        existing = db.query(NotebookShare).filter(
            NotebookShare.notebook_id == notebook_id,
            NotebookShare.user_id == user_id
        ).first()
        
        if not existing:
            share = NotebookShare(notebook_id=notebook_id, user_id=user_id)
            db.add(share)
    
    db.commit()
    
    return {"message": "Notebook shared successfully"}


@router.delete("/{notebook_id}/share/{user_id}")
def unshare_notebook(
    notebook_id: int,
    user_id: int,
    current_user: User = Depends(get_current_user_obj),
    db: Session = Depends(get_db)
):
    """
    🔓 Arrêter le partage avec un utilisateur
    """
    notebook = db.query(ProjectNotebook).filter(ProjectNotebook.id == notebook_id).first()
    
    if not notebook:
        raise HTTPException(status_code=404, detail="Notebook not found")
    
    # Vérifier les permissions
    if notebook.created_by != current_user.id:
        raise HTTPException(status_code=403, detail="Only creator can unshare")
    
    share = db.query(NotebookShare).filter(
        NotebookShare.notebook_id == notebook_id,
        NotebookShare.user_id == user_id
    ).first()
    
    if share:
        db.delete(share)
        db.commit()
    
    return {"message": "Sharing removed"}


# ═══════════════════════════════════════════════════════════════════════════
# VERSIONING
# ═══════════════════════════════════════════════════════════════════════════

@router.post("/{notebook_id}/versions")
def create_version(
    notebook_id: int,
    version_data: NotebookVersionCreate,
    current_user: User = Depends(get_current_user_obj),
    db: Session = Depends(get_db)
):
    """
    📸 Créer une snapshot/version du cahier
    """
    notebook = db.query(ProjectNotebook).filter(ProjectNotebook.id == notebook_id).first()
    
    if not notebook:
        raise HTTPException(status_code=404, detail="Notebook not found")
    
    version = NotebookVersion(
        notebook_id=notebook_id,
        title=notebook.title,
        change_description=version_data.change_description,
        created_by=current_user.id,
        sections_snapshot=notebook.sections
    )
    
    db.add(version)
    db.commit()
    db.refresh(version)
    
    return {
        "id": version.id,
        "notebook_id": version.notebook_id,
        "title": version.title,
        "change_description": version.change_description,
        "created_at": version.created_at
    }


@router.get("/{notebook_id}/versions", response_model=List[NotebookVersionResponse])
def get_versions(
    notebook_id: int,
    current_user: User = Depends(get_current_user_obj),
    db: Session = Depends(get_db)
):
    """
    📚 Récupérer l'historique des versions
    """
    notebook = db.query(ProjectNotebook).filter(ProjectNotebook.id == notebook_id).first()
    
    if not notebook:
        raise HTTPException(status_code=404, detail="Notebook not found")
    
    return db.query(NotebookVersion).filter(
        NotebookVersion.notebook_id == notebook_id
    ).order_by(NotebookVersion.created_at.desc()).all()


@router.post("/{notebook_id}/versions/{version_id}/restore")
def restore_version(
    notebook_id: int,
    version_id: int,
    current_user: User = Depends(get_current_user_obj),
    db: Session = Depends(get_db)
):
    """
    ⏮️ Restaurer une version antérieure
    """
    notebook = db.query(ProjectNotebook).filter(ProjectNotebook.id == notebook_id).first()
    
    if not notebook:
        raise HTTPException(status_code=404, detail="Notebook not found")
    
    # Vérifier les permissions
    if notebook.created_by != current_user.id:
        raise HTTPException(status_code=403, detail="Only creator can restore")
    
    version = db.query(NotebookVersion).filter(
        NotebookVersion.id == version_id,
        NotebookVersion.notebook_id == notebook_id
    ).first()
    
    if not version:
        raise HTTPException(status_code=404, detail="Version not found")
    
    # Créer une nouvelle version avant restauration
    new_version = NotebookVersion(
        notebook_id=notebook_id,
        title=notebook.title,
        change_description=f"Restored from version {version_id}",
        created_by=current_user.id,
        sections_snapshot=notebook.sections
    )
    db.add(new_version)
    
    # Restaurer le contenu
    notebook.sections = version.sections_snapshot
    notebook.updated_at = datetime.utcnow()
    
    db.commit()
    
    return {
        "message": "Version restored",
        "notebook_id": notebook_id,
        "restored_from_version": version_id
    }


# ═══════════════════════════════════════════════════════════════════════════
# SEARCH
# ═══════════════════════════════════════════════════════════════════════════

@router.get("/search")
def search_notebooks(
    query: str = Query(...),
    current_user: User = Depends(get_current_user_obj),
    db: Session = Depends(get_db)
):
    """
    🔍 Rechercher des cahiers par titre ou description
    """
    search_term = f"%{query}%"
    
    notebooks = db.query(ProjectNotebook).filter(
        (ProjectNotebook.created_by == current_user.id) |
        (ProjectNotebook.shares.any(NotebookShare.user_id == current_user.id)) |
        (ProjectNotebook.is_public == True),
        (ProjectNotebook.title.ilike(search_term) |
         ProjectNotebook.description.ilike(search_term))
    ).all()
    
    return notebooks
