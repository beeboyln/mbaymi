from fastapi import APIRouter, Query, HTTPException, Depends
from sqlalchemy import or_
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.user import User
from app.models.veterinarian import VeterinarianProfile
from app.models.farm import Farm

router = APIRouter(prefix="/api/search", tags=["search"])


@router.get("/users")
def search_users(
    q: str = Query("", min_length=1),
    type: str = Query("all", regex="^(all|farmer|veterinarian|farm)$"),
    region: str = Query(""),
    db: Session = Depends(get_db),
):
    """
    Recherche des utilisateurs, vétérinaires, et fermes.
    
    Paramètres:
    - q: terme de recherche (nom, email, etc.) - minimum 2 caractères
    - type: 'farmer', 'veterinarian', 'farm', ou 'all'
    - region: région pour filtrer
    """
    try:
        if not q:
            return {"results": []}
        
        results = []
        
        # Recherche d'agriculteurs
        if type in ["farmer", "all"]:
            farmers = db.query(User).filter(
                User.role.in_(["farmer", "livestock_breeder", "seller", "buyer"]),
                or_(
                    User.name.ilike(f"%{q}%"),
                    User.email.ilike(f"%{q}%"),
                    User.village.ilike(f"%{q}%"),
                )
            )
            
            if region:
                farmers = farmers.filter(User.region.ilike(f"%{region}%"))
            
            farmers = farmers.limit(10).all()
            
            for farmer in farmers:
                results.append({
                    "type": "farmer",
                    "id": farmer.id,
                    "name": farmer.name,
                    "email": farmer.email,
                    "phone": farmer.phone,
                    "role": farmer.role,
                    "region": farmer.region,
                    "village": farmer.village,
                    "profile_image": farmer.profile_image,
                })
        
        # Recherche de vétérinaires
        if type in ["veterinarian", "all"]:
            vets_query = db.query(VeterinarianProfile, User).join(
                User, User.id == VeterinarianProfile.user_id
            ).filter(
                User.role == "veterinarian",
                or_(
                    User.name.ilike(f"%{q}%"),
                    User.email.ilike(f"%{q}%"),
                    VeterinarianProfile.specialty.ilike(f"%{q}%"),
                    VeterinarianProfile.zone.ilike(f"%{q}%"),
                )
            )
            
            if region:
                vets_query = vets_query.filter(VeterinarianProfile.zone.ilike(f"%{region}%"))
            
            vets = vets_query.limit(10).all()
            
            for vet_profile, vet_user in vets:
                # S'assurer que le profil vétérinaire existe vraiment
                if vet_profile:
                    results.append({
                        "type": "veterinarian",
                        "id": vet_user.id,
                        "name": vet_user.name,
                        "email": vet_user.email,
                        "phone": vet_user.phone,
                        "profile_image": vet_user.profile_image,
                        "specialty": vet_profile.specialty,
                        "zone": vet_profile.zone,
                        "bio": vet_profile.bio,
                        "experience_years": vet_profile.experience_years,
                        "rating": float(vet_profile.average_rating) if vet_profile.average_rating else None,
                        "is_verified": vet_profile.is_verified,
                    })
        
        # Recherche de fermes
        if type in ["farm", "all"]:
            farms = db.query(Farm).filter(
                or_(
                    Farm.name.ilike(f"%{q}%"),
                    Farm.location.ilike(f"%{q}%"),
                )
            )
            
            if region:
                farms = farms.filter(Farm.region.ilike(f"%{region}%"))
            
            farms = farms.limit(10).all()
            
            for farm in farms:
                owner = db.query(User).filter(User.id == farm.user_id).first()
                results.append({
                    "type": "farm",
                    "id": farm.id,
                    "name": farm.name,
                    "location": farm.location,
                    "region": farm.region,
                    "owner_name": owner.name if owner else "Inconnu",
                    "owner_id": farm.user_id,
                })
        
        # Trier par pertinence (les noms exacts d'abord)
        results.sort(
            key=lambda x: (
                x["name"].lower() != q.lower(),
                x["name"].lower().find(q.lower()),
            )
        )
        
        return {"results": results}
        
    except Exception as e:
        print(f"Search error: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/users/trending")
def trending_users(
    db: Session = Depends(get_db),
):
    """
    Retourne les utilisateurs les plus populaires/vérifiés
    """
    try:
        # Vétérinaires vérifiés avec bonne note
        vets = db.query(VeterinarianProfile, User).join(
            User, User.id == VeterinarianProfile.user_id
        ).filter(
            VeterinarianProfile.is_verified == True,
            VeterinarianProfile.average_rating >= 4.0,
        ).limit(5).all()
        
        results = []
        for vet_profile, vet_user in vets:
            results.append({
                "type": "veterinarian",
                "id": vet_profile.id,
                "name": vet_user.name,
                "specialty": vet_profile.specialty,
                "rating": float(vet_profile.average_rating) if vet_profile.average_rating else None,
                "is_verified": True,
            })
        
        return {"results": results}
        
    except Exception as e:
        print(f"Trending users error: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))
