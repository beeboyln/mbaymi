from fastapi import APIRouter
import requests
import re
from xml.etree import ElementTree as ET
from datetime import datetime
from typing import List, Dict, Any

router = APIRouter(prefix="/api/news", tags=["news"])

@router.get("/agricultural")
async def get_agricultural_news():
    """
    Fetch agricultural news from multiple sources and categories.
    Returns agriculture, livestock, local (Senegal), and international news.
    """
    try:
        articles = []
        
        # Define multiple Google News RSS feeds
        feeds = [
            {
                "url": "https://news.google.com/rss?q=agriculture&ceid=SN:fr",
                "category": "Agriculture",
                "description": "Actualités agricoles"
            },
            {
                "url": "https://news.google.com/rss?q=élevage+bétail&ceid=SN:fr",
                "category": "Élevage",
                "description": "Actualités d'élevage"
            },
            {
                "url": "https://news.google.com/rss?q=Senegal+agriculture&ceid=SN:fr",
                "category": "Local",
                "description": "Actualités locales Sénégal"
            },
            {
                "url": "https://news.google.com/rss?q=agriculture+international&hl=fr",
                "category": "International",
                "description": "Actualités internationales"
            },
        ]
        
        # Fetch from each feed
        for feed_config in feeds:
            try:
                response = requests.get(feed_config["url"], timeout=8)
                response.raise_for_status()
                
                # Parse RSS XML
                root = ET.fromstring(response.content)
                
                # Iterate through RSS items (limit to 3 per feed)
                items_count = 0
                for item in root.findall('.//item'):
                    if items_count >= 3:
                        break
                    
                    # Extract fields
                    title_elem = item.find('title')
                    description_elem = item.find('description')
                    link_elem = item.find('link')
                    pubDate_elem = item.find('pubDate')
                    image_elem = item.find('.//image/url')
                    
                    title = title_elem.text if title_elem is not None else feed_config["description"]
                    description = description_elem.text if description_elem is not None else ""
                    link = link_elem.text if link_elem is not None else ""
                    pub_date_str = pubDate_elem.text if pubDate_elem is not None else ""
                    image_url = image_elem.text if image_elem is not None else None
                    
                    # Skip if no title
                    if not title:
                        continue
                    
                    # Clean HTML tags and entities from description
                    description = re.sub(r'<[^>]*>', '', description)
                    # Clean HTML entities
                    description = description.replace('&nbsp;', ' ')
                    description = description.replace('&quot;', '"')
                    description = description.replace('&apos;', "'")
                    description = description.replace('&amp;', '&')
                    description = description.replace('&lt;', '<')
                    description = description.replace('&gt;', '>')
                    description = description.replace('&#39;', "'")
                    description = re.sub(r'&#\d+;', '', description)  # Remove numeric entities
                    description = description.strip()
                    # Remove extra whitespace
                    description = ' '.join(description.split())
                    
                    # Limit description to 300 characters (increased from 150)
                    if len(description) > 300:
                        description = description[:300] + "..."
                    
                    # Parse publication date
                    try:
                        pub_date = datetime.strptime(pub_date_str, "%a, %d %b %Y %H:%M:%S %Z")
                    except:
                        try:
                            pub_date = datetime.strptime(pub_date_str, "%a, %d %b %Y %H:%M:%S %z")
                        except:
                            pub_date = datetime.now()
                    
                    articles.append({
                        "title": title,
                        "description": description,
                        "imageUrl": image_url,
                        "pubDate": pub_date.isoformat(),
                        "source": feed_config["description"],
                        "category": feed_config["category"],
                        "link": link,
                    })
                    
                    items_count += 1
            except Exception as e:
                # Continue with next feed if this one fails
                print(f"Error fetching {feed_config['category']} news: {str(e)}")
                continue
        
        # If no articles were fetched, return default news
        if not articles:
            return {
                "status": "fallback",
                "message": "Could not fetch live news",
                "articles": _get_default_news()
            }
        
        return {
            "status": "success",
            "count": len(articles),
            "articles": articles
        }
    
    except Exception as e:
        # Return default news if something goes wrong
        return {
            "status": "fallback",
            "message": f"Error: {str(e)}",
            "articles": _get_default_news()
        }

def _get_default_news() -> List[Dict[str, Any]]:
    """Return default news articles if RSS fetch fails"""
    return [
        {
            "title": "Alerte Météo",
            "description": "Pluie prévue ce weekend - Bonne nouvelle pour les cultures",
            "imageUrl": None,
            "pubDate": datetime.now().isoformat(),
            "source": "Météo",
            "category": "Météo",
        },
        {
            "title": "Prix en hausse",
            "description": "Le maïs atteint 850 FCFA/kg - Plus haut en 30 jours",
            "imageUrl": None,
            "pubDate": datetime.now().isoformat(),
            "source": "Marché",
            "category": "Prix",
        },
        {
            "title": "Alerte Ravageurs",
            "description": "Attention aux chenilles légionnaires dans votre région",
            "imageUrl": None,
            "pubDate": datetime.now().isoformat(),
            "source": "Alertes",
            "category": "Santé des cultures",
        },
        {
            "title": "Conseil Irrigation",
            "description": "Augmentez l'irrigation de 20% cette semaine",
            "imageUrl": None,
            "pubDate": datetime.now().isoformat(),
            "source": "Conseils",
            "category": "Technique",
        },
        {
            "title": "Vaccin disponible",
            "description": "Nouveau vaccin pour le bétail arrivé - Réservez maintenant",
            "imageUrl": None,
            "pubDate": datetime.now().isoformat(),
            "source": "Vétérinaire",
            "category": "Santé animale",
        },
    ]
