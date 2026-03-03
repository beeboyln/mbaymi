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
    type: str = Query("all", pattern="^(all|farmer|livestock_breeder|veterinarian|farm)$"),
    region: str = Query(""),
    db: Session = Depends(get_db),
):
    """
    Recherche des utilisateurs, vétérinaires, et fermes.
    
    Paramètres:
    - q: terme de recherche (nom, email, etc.) - minimum 2 caractères
    - type: 'farmer', 'livestock_breeder', 'veterinarian', 'farm', ou 'all'
    - region: région pour filtrer
    """
    try:
        if not q or len(q.strip()) == 0:
            return {"results": []}
        
        results = []
        
        # Recherche d'agriculteurs
        if type in ["farmer", "all"]:
            try:
                farmers = db.query(User).filter(
                    User.role == "farmer",
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
                    if farmer.id is not None and farmer.name is not None:
                        results.append({
                            "type": "farmer",
                            "id": farmer.id,
                            "name": farmer.name or "Agriculteur",
                            "email": farmer.email,
                            "phone": farmer.phone or "",
                            "role": farmer.role,
                            "region": farmer.region or "",
                            "village": farmer.village or "",
                            "profile_image": farmer.profile_image or "",
                        })
            except Exception as e:
                print(f"Error searching farmers: {str(e)}")
        
        # Recherche d'éleveurs
        if type in ["livestock_breeder", "all"]:
            try:
                breeders = db.query(User).filter(
                    User.role == "livestock_breeder",
                    or_(
                        User.name.ilike(f"%{q}%"),
                        User.email.ilike(f"%{q}%"),
                        User.village.ilike(f"%{q}%"),
                    )
                )
                
                if region:
                    breeders = breeders.filter(User.region.ilike(f"%{region}%"))
                
                breeders = breeders.limit(10).all()
                
                for breeder in breeders:
                    if breeder.id is not None and breeder.name is not None:
                        results.append({
                            "type": "livestock_breeder",
                            "id": breeder.id,
                            "name": breeder.name or "Éleveur",
                            "email": breeder.email,
                            "phone": breeder.phone or "",
                            "role": breeder.role,
                            "region": breeder.region or "",
                            "village": breeder.village or "",
                            "profile_image": breeder.profile_image or "",
                        })
            except Exception as e:
                print(f"Error searching livestock breeders: {str(e)}")
        
        # Recherche de vétérinaires
        if type in ["veterinarian", "all"]:
            try:
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
                    if vet_profile and vet_profile.id is not None and vet_user.id is not None:
                        results.append({
                            "type": "veterinarian",
                            "id": vet_user.id,
                            "name": vet_user.name or "Vétérinaire",
                            "email": vet_user.email,
                            "phone": vet_user.phone or "",
                            "profile_image": vet_user.profile_image or "",
                            "specialty": vet_profile.specialty or "Généraliste",
                            "zone": vet_profile.zone or "",
                            "bio": vet_profile.bio or "",
                            "experience_years": vet_profile.experience_years or 0,
                            "rating": float(vet_profile.average_rating) if vet_profile.average_rating else None,
                            "is_verified": vet_profile.is_verified or False,
                        })
            except Exception as e:
                print(f"Error searching veterinarians: {str(e)}")
        
        # Recherche de fermes
        if type in ["farm", "all"]:
            try:
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
                    if farm.id is not None and farm.name is not None:
                        owner_name = "Inconnu"
                        try:
                            owner = db.query(User).filter(User.id == farm.user_id).first()
                            if owner:
                                owner_name = owner.name or "Propriétaire inconnu"
                        except Exception as e:
                            print(f"Error fetching farm owner: {str(e)}")
                        
                        results.append({
                            "type": "farm",
                            "id": farm.id,
                            "name": farm.name or "Ferme",
                            "location": farm.location or "",
                            "region": farm.region or "",
                            "owner_name": owner_name,
                            "owner_id": farm.user_id or None,
                        })
            except Exception as e:
                print(f"Error searching farms: {str(e)}")
        
        # Trier par pertinence (les noms exacts d'abord)
        try:
            results.sort(
                key=lambda x: (
                    x.get("name", "").lower() != q.lower(),
                    x.get("name", "").lower().find(q.lower()),
                )
            )
        except Exception as e:
            print(f"Error sorting results: {str(e)}")
        
        return {"results": results}
        
    except Exception as e:
        print(f"Search error: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Erreur lors de la recherche: {str(e)}")


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
