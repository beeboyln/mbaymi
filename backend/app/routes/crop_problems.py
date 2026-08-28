from fastapi import APIRouter, Depends, HTTPException, Query, Body
from sqlalchemy.orm import Session
from datetime import datetime
from pydantic import BaseModel
from typing import Optional
from app.database import get_db
from app.models import CropProblem, Crop, Farm
from app.models.input import Input
from app.models.finance import FinanceTransaction

router = APIRouter(prefix="/api/crop-problems", tags=["Crop Problems"])

# ═══════════════════════════════════════════════════════════════════════════
# MODELS
# ═══════════════════════════════════════════════════════════════════════════

class CropProblemCreate(BaseModel):
    crop_id: int
    farm_id: int
    user_id: int
    problem_type: str  # yellowing, leaf_holes, poor_yield, rot, pest, disease
    description: str = ""
    photo_url: Optional[str] = None
    severity: str = "medium"  # low, medium, high
    input_id: Optional[int] = None
    quantity_used: Optional[float] = None
    finance_type: Optional[str] = None
    finance_amount: Optional[float] = None

class UpdateProblemStatus(BaseModel):
    status: str  # identified, treated, resolved
    treatment_notes: Optional[str] = None

# ═══════════════════════════════════════════════════════════════════════════
# CROP PROBLEMS ENDPOINTS (Maladies & Ravageurs)
# ═══════════════════════════════════════════════════════════════════════════

@router.post("/")
def report_crop_problem(
    problem: CropProblemCreate,
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
        crop = db.query(Crop).filter(Crop.id == problem.crop_id, Crop.farm_id == problem.farm_id).first()
        if not crop:
            raise HTTPException(status_code=404, detail="Culture non trouvée")

        input_item = None
        if problem.input_id is not None:
            input_item = db.query(Input).filter(
                Input.id == problem.input_id,
                Input.farm_id == problem.farm_id,
                (Input.crop_id == problem.crop_id) | Input.crop_id.is_(None),
            ).first()
            if not input_item or problem.quantity_used is None or problem.quantity_used <= 0:
                raise HTTPException(status_code=400, detail="Intrant ou quantité de traitement invalide")
            if input_item.quantity is None or problem.quantity_used > input_item.quantity:
                raise HTTPException(status_code=400, detail="Stock de médicament insuffisant")
            input_item.quantity -= problem.quantity_used
        if problem.finance_amount is not None and problem.finance_amount > 0 and problem.finance_type not in ('expense', 'income'):
            raise HTTPException(status_code=400, detail="finance_type must be expense or income")
        
        # Créer le problème
        crop_problem = CropProblem(
            crop_id=problem.crop_id,
            farm_id=problem.farm_id,
            user_id=problem.user_id,
            problem_type=problem.problem_type,
            description=problem.description,
            photo_url=problem.photo_url,
            severity=problem.severity,
            status="reported",
            input_id=problem.input_id,
            quantity_used=problem.quantity_used,
            finance_type=problem.finance_type,
            finance_amount=problem.finance_amount,
        )
        db.add(crop_problem)
        db.commit()
        db.refresh(crop_problem)
        if problem.finance_amount is not None and problem.finance_amount > 0:
            db.add(FinanceTransaction(
                farm_id=problem.farm_id, crop_id=problem.crop_id,
                problem_id=crop_problem.id, transaction_type=problem.finance_type,
                category=f"Traitement - {problem.problem_type}", amount=problem.finance_amount,
                notes=problem.description,
            ))
            db.commit()
        
        return {
            "id": crop_problem.id,
            "crop_id": crop_problem.crop_id,
            "problem_type": crop_problem.problem_type,
            "severity": crop_problem.severity,
            "status": crop_problem.status,
            "created_at": crop_problem.created_at.isoformat(),
            "message": "✅ Problème signalé avec succès"
        }
    except HTTPException:
        db.rollback()
        raise
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
    data: UpdateProblemStatus,
    db: Session = Depends(get_db)
):
    """
    ✅ Mettre à jour le statut d'un problème (traité, résolu, etc).
    """
    try:
        problem = db.query(CropProblem).filter(CropProblem.id == problem_id).first()
        if not problem:
            raise HTTPException(status_code=404, detail="Problème non trouvé")
        
        problem.status = data.status
        if data.treatment_notes:
            problem.treatment_notes = data.treatment_notes
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
