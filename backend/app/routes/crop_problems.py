from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from datetime import datetime
from app.database import get_db
from app.models import CropProblem, Crop, Farm

router = APIRouter(prefix="/api/crop-problems", tags=["Crop Problems"])

# ═══════════════════════════════════════════════════════════════════════════
# CROP PROBLEMS ENDPOINTS (Maladies & Ravageurs)
# ═══════════════════════════════════════════════════════════════════════════

@router.post("/")
def report_crop_problem(
    crop_id: int,
    farm_id: int,
    user_id: int,
    problem_type: str,  # yellowing, leaf_holes, poor_yield, rot, pest, disease
    description: str = "",
    photo_url: str = None,
    severity: str = "medium",  # low, medium, high
    db: Session = Depends(get_db)
):
    """
    📸 Signaler un problème sur une culture.
    
    Exemple :
    {
        "crop_id": 1,
        "farm_id": 1,
        "user_id": 1,
        "problem_type": "yellowing",
        "description": "Les feuilles deviennent jaunes, probablement manque d'eau",
        "photo_url": "https://...",
        "severity": "high"
    }
    """
    try:
        # Vérifier que la culture existe
        crop = db.query(Crop).filter(Crop.id == crop_id, Crop.farm_id == farm_id).first()
        if not crop:
            raise HTTPException(status_code=404, detail="Culture non trouvée")
        
        # Créer le problème
        problem = CropProblem(
            crop_id=crop_id,
            farm_id=farm_id,
            user_id=user_id,
            problem_type=problem_type,
            description=description,
            photo_url=photo_url,
            severity=severity,
            status="reported",
        )
        db.add(problem)
        db.commit()
        db.refresh(problem)
        
        return {
            "id": problem.id,
            "crop_id": problem.crop_id,
            "problem_type": problem.problem_type,
            "severity": problem.severity,
            "status": problem.status,
            "created_at": problem.created_at.isoformat(),
            "message": "✅ Problème signalé avec succès"
        }
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Erreur : {str(e)}")


@router.get("/crop/{crop_id}")
def get_crop_problems(crop_id: int, db: Session = Depends(get_db)):
    """
    📋 Récupérer tous les problèmes signalés pour une culture.
    """
    try:
        problems = db.query(CropProblem).filter(CropProblem.crop_id == crop_id).order_by(CropProblem.created_at.desc()).all()
        
        return {
            "count": len(problems),
            "problems": [
                {
                    "id": p.id,
                    "problem_type": p.problem_type,
                    "description": p.description,
                    "photo_url": p.photo_url,
                    "severity": p.severity,
                    "status": p.status,
                    "created_at": p.created_at.isoformat(),
                    "treatment_notes": p.treatment_notes,
                }
                for p in problems
            ]
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erreur : {str(e)}")


@router.get("/farm/{farm_id}")
def get_farm_problems(farm_id: int, db: Session = Depends(get_db)):
    """
    🚨 Récupérer tous les problèmes signalés pour une ferme.
    """
    try:
        problems = db.query(CropProblem).filter(CropProblem.farm_id == farm_id).order_by(CropProblem.created_at.desc()).all()
        
        return {
            "count": len(problems),
            "problems": [
                {
                    "id": p.id,
                    "crop_id": p.crop_id,
                    "problem_type": p.problem_type,
                    "description": p.description,
                    "photo_url": p.photo_url,
                    "severity": p.severity,
                    "status": p.status,
                    "created_at": p.created_at.isoformat(),
                }
                for p in problems
            ]
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erreur : {str(e)}")


@router.put("/{problem_id}/status")
def update_problem_status(
    problem_id: int,
    status: str,  # identified, treated, resolved
    treatment_notes: str = None,
    db: Session = Depends(get_db)
):
    """
    ✅ Mettre à jour le statut d'un problème (traité, résolu, etc).
    """
    try:
        problem = db.query(CropProblem).filter(CropProblem.id == problem_id).first()
        if not problem:
            raise HTTPException(status_code=404, detail="Problème non trouvé")
        
        problem.status = status
        if treatment_notes:
            problem.treatment_notes = treatment_notes
        problem.updated_at = datetime.utcnow()
        
        db.commit()
        db.refresh(problem)
        
        return {
            "id": problem.id,
            "status": problem.status,
            "treatment_notes": problem.treatment_notes,
            "updated_at": problem.updated_at.isoformat(),
        }
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Erreur : {str(e)}")


@router.delete("/{problem_id}")
def delete_problem(problem_id: int, db: Session = Depends(get_db)):
    """
    🗑️ Supprimer un problème signalé.
    """
    try:
        problem = db.query(CropProblem).filter(CropProblem.id == problem_id).first()
        if not problem:
            raise HTTPException(status_code=404, detail="Problème non trouvé")
        
        db.delete(problem)
        db.commit()
        
        return {"message": "Problème supprimé"}
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Erreur : {str(e)}")
