"""
FARM DELETION SERVICE
Complete guide for safely deleting all farm-related data while respecting foreign key constraints

CRITICAL: This service must handle transactions properly and execute in the correct order.
"""

from sqlalchemy.orm import Session
from sqlalchemy import delete
from app.models import (
    # Phase 1: Leaf entities
    FarmPostLike, FarmPostComment, FarmPostShare,
    ActivityPhoto, AnimalPhoto,
    # Phase 2: Dependent entities
    Consultation, Sale,
    # Phase 3: Farm data - no cascade
    CropProblem, Reminder, FinanceTransaction, Harvest,
    Activity, FarmPost, ServiceRequest, Authorization,
    FarmFollowing, FarmProfile,
    # Phase 4: Farm data - with cascade
    FarmImagePost, FarmPhoto, Input,
    # Phase 5: Root dependencies
    Crop,
    # Phase 6: The farm itself
    Farm
)


class FarmDeletionService:
    """
    Service to safely delete a farm and all associated data.
    
    DELETION ORDER (MUST be followed strictly):
    
    Phase 1: Delete leaf-level entities (cascade to parent)
      1. FarmPostLike
      2. FarmPostComment  
      3. FarmPostShare
      4. ActivityPhoto
      5. AnimalPhoto (if applicable)
    
    Phase 2: Delete dependent entities
      6. Consultation
      7. Sale
    
    Phase 3: Delete farm data (NO cascade - manual deletion)
      8. CropProblem
      9. Reminder
      10. FinanceTransaction
      11. Harvest
      12. Activity
      13. FarmPost
      14. ServiceRequest
      15. Authorization (⚠️ No FK constraint - potential issue)
      16. FarmFollowing
      17. FarmProfile
    
    Phase 4: Delete farm data (WITH cascade)
      18. FarmImagePost
      19. FarmPhoto
      20. Input
    
    Phase 5: Delete Crops
      21. Crop
    
    Phase 6: Delete Farm
      22. Farm
    """

    def __init__(self, db: Session):
        self.db = db
        self.deleted_counts = {}

    def delete_farm(self, farm_id: int) -> dict:
        """
        Delete all data associated with a farm.
        
        Returns:
            dict: {
                'success': bool,
                'deleted_counts': {model_name: count},
                'errors': [error_messages]
            }
        """
        try:
            return self._execute_deletion_phases(farm_id)
        except Exception as e:
            self.db.rollback()
            return {
                'success': False,
                'deleted_counts': self.deleted_counts,
                'errors': [str(e)]
            }

    def _execute_deletion_phases(self, farm_id: int) -> dict:
        """Execute all deletion phases in order."""
        errors = []
        
        try:
            # Phase 1: Leaf-level entities (cascade from parent will handle these)
            self._delete_phase_1(farm_id, errors)
            
            # Phase 2: Dependent entities
            self._delete_phase_2(farm_id, errors)
            
            # Phase 3: Farm data - NO cascade constraints
            self._delete_phase_3(farm_id, errors)
            
            # Phase 4: Farm data - WITH cascade constraints
            self._delete_phase_4(farm_id, errors)
            
            # Phase 5: Crops (has cascade)
            self._delete_phase_5(farm_id, errors)
            
            # Phase 6: Farm itself
            self._delete_phase_6(farm_id, errors)
            
            self.db.commit()
            
            return {
                'success': True,
                'deleted_counts': self.deleted_counts,
                'errors': errors if errors else None
            }
            
        except Exception as e:
            self.db.rollback()
            errors.append(f"Critical error in deletion: {str(e)}")
            return {
                'success': False,
                'deleted_counts': self.deleted_counts,
                'errors': errors
            }

    def _delete_phase_1(self, farm_id: int, errors: list):
        """
        Phase 1: Delete leaf-level entities
        
        These cascade from their parents (FarmImagePost, Activity, Livestock).
        We delete them first to simplify later deletions.
        """
        try:
            # FarmPostLike - cascades from FarmImagePost
            count = self.db.query(FarmPostLike).filter(
                FarmPostLike.farm_post_id.in_(
                    self.db.query(FarmImagePost.id).filter(FarmImagePost.farm_id == farm_id)
                )
            ).delete(synchronize_session=False)
            self.deleted_counts['FarmPostLike'] = count

            # FarmPostComment - cascades from FarmImagePost
            count = self.db.query(FarmPostComment).filter(
                FarmPostComment.farm_post_id.in_(
                    self.db.query(FarmImagePost.id).filter(FarmImagePost.farm_id == farm_id)
                )
            ).delete(synchronize_session=False)
            self.deleted_counts['FarmPostComment'] = count

            # FarmPostShare - cascades from FarmImagePost
            count = self.db.query(FarmPostShare).filter(
                FarmPostShare.farm_post_id.in_(
                    self.db.query(FarmImagePost.id).filter(FarmImagePost.farm_id == farm_id)
                )
            ).delete(synchronize_session=False)
            self.deleted_counts['FarmPostShare'] = count

            # ActivityPhoto - cascades from Activity
            count = self.db.query(ActivityPhoto).filter(
                ActivityPhoto.activity_id.in_(
                    self.db.query(Activity.id).filter(Activity.farm_id == farm_id)
                )
            ).delete(synchronize_session=False)
            self.deleted_counts['ActivityPhoto'] = count
            
        except Exception as e:
            errors.append(f"Phase 1 error: {str(e)}")
            raise

    def _delete_phase_2(self, farm_id: int, errors: list):
        """
        Phase 2: Delete dependent entities that reference phase 1
        
        These tables reference entities from phase 1, so we delete them next.
        """
        try:
            # Consultation - depends on ServiceRequest
            count = self.db.query(Consultation).filter(
                Consultation.service_request_id.in_(
                    self.db.query(ServiceRequest.id).filter(ServiceRequest.farm_id == farm_id)
                )
            ).delete(synchronize_session=False)
            self.deleted_counts['Consultation'] = count

            # Sale - depends on Harvest
            count = self.db.query(Sale).filter(
                Sale.harvest_id.in_(
                    self.db.query(Harvest.id).filter(Harvest.farm_id == farm_id)
                )
            ).delete(synchronize_session=False)
            self.deleted_counts['Sale'] = count
            
        except Exception as e:
            errors.append(f"Phase 2 error: {str(e)}")
            raise

    def _delete_phase_3(self, farm_id: int, errors: list):
        """
        Phase 3: Delete farm data with NO cascade constraints
        
        ⚠️ CRITICAL: These tables reference the farm but have NO cascade delete.
        They MUST be deleted manually in this phase.
        """
        try:
            # CropProblem - references Crop & Farm
            count = self.db.query(CropProblem).filter(
                CropProblem.farm_id == farm_id
            ).delete(synchronize_session=False)
            self.deleted_counts['CropProblem'] = count

            # Reminder - references Farm & Crop
            count = self.db.query(Reminder).filter(
                Reminder.farm_id == farm_id
            ).delete(synchronize_session=False)
            self.deleted_counts['Reminder'] = count

            # FinanceTransaction - references Farm & Crop
            count = self.db.query(FinanceTransaction).filter(
                FinanceTransaction.farm_id == farm_id
            ).delete(synchronize_session=False)
            self.deleted_counts['FinanceTransaction'] = count

            # Harvest - references Farm & Crop
            count = self.db.query(Harvest).filter(
                Harvest.farm_id == farm_id
            ).delete(synchronize_session=False)
            self.deleted_counts['Harvest'] = count

            # Activity - references Farm & Crop
            count = self.db.query(Activity).filter(
                Activity.farm_id == farm_id
            ).delete(synchronize_session=False)
            self.deleted_counts['Activity'] = count

            # FarmPost - references Farm & Crop
            count = self.db.query(FarmPost).filter(
                FarmPost.farm_id == farm_id
            ).delete(synchronize_session=False)
            self.deleted_counts['FarmPost'] = count

            # ServiceRequest - references Farm (NO FK constraint!)
            count = self.db.query(ServiceRequest).filter(
                ServiceRequest.farm_id == farm_id
            ).delete(synchronize_session=False)
            self.deleted_counts['ServiceRequest'] = count

            # Authorization - references Farm (NO FK constraint!)
            count = self.db.query(Authorization).filter(
                Authorization.farm_id == farm_id
            ).delete(synchronize_session=False)
            self.deleted_counts['Authorization'] = count

            # FarmFollowing - references Farm
            count = self.db.query(FarmFollowing).filter(
                FarmFollowing.farm_id == farm_id
            ).delete(synchronize_session=False)
            self.deleted_counts['FarmFollowing'] = count

            # FarmProfile - references Farm (unique=True)
            count = self.db.query(FarmProfile).filter(
                FarmProfile.farm_id == farm_id
            ).delete(synchronize_session=False)
            self.deleted_counts['FarmProfile'] = count
            
        except Exception as e:
            errors.append(f"Phase 3 error: {str(e)}")
            raise

    def _delete_phase_4(self, farm_id: int, errors: list):
        """
        Phase 4: Delete farm data WITH cascade constraints
        
        These tables have cascade delete, but we delete them here before Crops
        to ensure data consistency.
        """
        try:
            # FarmImagePost - has cascade delete on farm_id
            count = self.db.query(FarmImagePost).filter(
                FarmImagePost.farm_id == farm_id
            ).delete(synchronize_session=False)
            self.deleted_counts['FarmImagePost'] = count

            # FarmPhoto - has cascade delete on farm_id
            count = self.db.query(FarmPhoto).filter(
                FarmPhoto.farm_id == farm_id
            ).delete(synchronize_session=False)
            self.deleted_counts['FarmPhoto'] = count

            # Input - has cascade delete on both farm_id AND crop_id
            count = self.db.query(Input).filter(
                Input.farm_id == farm_id
            ).delete(synchronize_session=False)
            self.deleted_counts['Input'] = count
            
        except Exception as e:
            errors.append(f"Phase 4 error: {str(e)}")
            raise

    def _delete_phase_5(self, farm_id: int, errors: list):
        """
        Phase 5: Delete Crops
        
        Crops have cascade delete on farm_id, so they will auto-delete
        any remaining Input rows. But we already deleted Inputs in Phase 4.
        """
        try:
            count = self.db.query(Crop).filter(
                Crop.farm_id == farm_id
            ).delete(synchronize_session=False)
            self.deleted_counts['Crop'] = count
            
        except Exception as e:
            errors.append(f"Phase 5 error: {str(e)}")
            raise

    def _delete_phase_6(self, farm_id: int, errors: list):
        """
        Phase 6: Delete the Farm itself
        
        Final step after all dependent data is deleted.
        """
        try:
            farm = self.db.query(Farm).filter(Farm.id == farm_id).first()
            if farm:
                self.db.delete(farm)
                self.deleted_counts['Farm'] = 1
            else:
                errors.append(f"Farm with id {farm_id} not found")
                
        except Exception as e:
            errors.append(f"Phase 6 error: {str(e)}")
            raise


# Example usage in a route:
"""
@router.delete("/farms/{farm_id}")
def delete_farm(farm_id: int, db: Session = Depends(get_db)):
    '''Delete a farm and all associated data'''
    service = FarmDeletionService(db)
    result = service.delete_farm(farm_id)
    
    if result['success']:
        return {
            'message': 'Farm successfully deleted',
            'deleted_records': result['deleted_counts']
        }
    else:
        raise HTTPException(
            status_code=500,
            detail=f"Deletion failed: {result['errors']}"
        )
"""
