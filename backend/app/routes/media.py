from fastapi import APIRouter
from fastapi.responses import Response
import requests
from functools import lru_cache
import logging

router = APIRouter(prefix="/api/media", tags=["media"])
logger = logging.getLogger(__name__)

# Cache la vidéo en mémoire pour éviter les requêtes répétées
@lru_cache(maxsize=1)
def _get_video_data():
    """Récupère la vidéo de Cloudinary une fois et la met en cache"""
    try:
        url = 'https://res.cloudinary.com/dcs9vkwe0/video/upload/v1769204706/aispqon3tonh9wuqlrai.mp4'
        response = requests.get(url, timeout=30)
        response.raise_for_status()
        return response.content
    except Exception as e:
        logger.error(f"Erreur récupération vidéo: {e}")
        return None

@router.get('/video/farm-hero')
async def get_farm_hero_video():
    """
    Sert la vidéo de la ferme avec les bons headers CORS
    Bypass les problèmes de Tracking Prevention en servant depuis notre domaine
    """
    try:
        video_data = _get_video_data()
        
        if video_data is None:
            return Response('Video not found', status_code=404)
        
        response = Response(video_data, media_type='video/mp4')
        
        # Headers CORS pour permettre l'accès cross-origin
        response.headers['Access-Control-Allow-Origin'] = '*'
        response.headers['Access-Control-Allow-Methods'] = 'GET, OPTIONS'
        response.headers['Access-Control-Allow-Headers'] = 'Content-Type'
        
        # Headers de cache pour optimiser les performances
        response.headers['Cache-Control'] = 'public, max-age=86400'  # 24h
        response.headers['Content-Type'] = 'video/mp4'
        
        # Headers de sécurité
        response.headers['X-Content-Type-Options'] = 'nosniff'
        
        return response
    
    except Exception as e:
        logger.error(f"Erreur serveur: {e}")
        return Response('Internal server error', status_code=500)

@router.options('/video/farm-hero')
async def video_options():
    """Handle CORS preflight requests"""
    response = Response()
    response.headers['Access-Control-Allow-Origin'] = '*'
    response.headers['Access-Control-Allow-Methods'] = 'GET, OPTIONS'
    response.headers['Access-Control-Allow-Headers'] = 'Content-Type'
    return response

