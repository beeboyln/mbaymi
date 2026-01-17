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
                    content_elem = item.find('content:encoded')
                    
                    title = title_elem.text if title_elem is not None else feed_config["description"]
                    description = description_elem.text if description_elem is not None else ""
                    link = link_elem.text if link_elem is not None else ""
                    pub_date_str = pubDate_elem.text if pubDate_elem is not None else ""
                    image_url = image_elem.text if image_elem is not None else None
                    content = content_elem.text if content_elem is not None else ""
                    
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
                    
                    # Clean content if it exists
                    if content:
                        content = re.sub(r'<[^>]*>', '', content)
                        content = content.replace('&nbsp;', ' ')
                        content = content.replace('&quot;', '"')
                        content = content.replace('&apos;', "'")
                        content = content.replace('&amp;', '&')
                        content = content.replace('&lt;', '<')
                        content = content.replace('&gt;', '>')
                        content = content.replace('&#39;', "'")
                        content = re.sub(r'&#\d+;', '', content)
                        content = content.strip()
                        content = ' '.join(content.split())
                    else:
                        # If no content:encoded, use description as content
                        content = description
                    
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
                        "content": content,
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
            "content": "Les prévisions météorologiques indiquent une arrivée de pluies ce weekend. Cela représente une excellente nouvelle pour vos cultures qui bénéficieront de cette humidité naturelle. Les agriculteurs doivent se préparer à arrêter l'irrigation si elle était prévue. Les accumulations de pluie devraient être de 20 à 40 mm selon les régions. Cette pluie favorisera la croissance des cultures et réduira le stress hydrique.",
            "imageUrl": None,
            "pubDate": datetime.now().isoformat(),
            "source": "Météo",
            "category": "Météo",
        },
        {
            "title": "Prix en hausse",
            "description": "Le maïs atteint 850 FCFA/kg - Plus haut en 30 jours",
            "content": "Le cours du maïs a atteint 850 FCFA par kilogramme, marquant le plus haut niveau depuis 30 jours. Cette hausse est due à la baisse des stocks nationaux et à la demande croissante des marchés régionaux. Les experts recommandent aux producteurs de bien évaluer leurs stocks avant de vendre, car cette tendance pourrait s'accentuer dans les semaines à venir. Les consommateurs sont également impactés par cette augmentation des prix.",
            "imageUrl": None,
            "pubDate": datetime.now().isoformat(),
            "source": "Marché",
            "category": "Prix",
        },
        {
            "title": "Alerte Ravageurs",
            "description": "Attention aux chenilles légionnaires dans votre région",
            "content": "Une alerte a été émise concernant la présence de chenilles légionnaires (Spodoptera frugiperda) dans plusieurs zones agricoles de la région. Ces ravageurs sont particulièrement destructeurs pour le maïs et le sorgho. Les agriculteurs doivent inspecter régulièrement leurs cultures et appliquer des mesures de lutte intégrée. Consultez un agent vétérinaire pour les options de traitement recommandées. Les pièges à phéromones sont efficaces pour le monitoring.",
            "imageUrl": None,
            "pubDate": datetime.now().isoformat(),
            "source": "Alertes",
            "category": "Santé des cultures",
        },
        {
            "title": "Conseil Irrigation",
            "description": "Augmentez l'irrigation de 20% cette semaine",
            "content": "En raison de l'augmentation des températures et de la baisse de l'humidité relative, il est recommandé d'augmenter l'irrigation de vos cultures de 20% cette semaine. Les cultures au stade de croissance active consomment plus d'eau. Assurez-vous que votre système d'irrigation fonctionne correctement et que l'eau atteint les racines. Un arrosage adéquat améliora la productivité de vos cultures et réduira les pertes.",
            "imageUrl": None,
            "pubDate": datetime.now().isoformat(),
            "source": "Conseils",
            "category": "Technique",
        },
        {
            "title": "Vaccin disponible",
            "description": "Nouveau vaccin pour le bétail arrivé - Réservez maintenant",
            "content": "Un nouveau vaccin polyvalent pour le bétail est maintenant disponible dans les cliniques vétérinaires agréées. Ce vaccin offre une protection contre les principales maladies infectieuses du bétail. La campagne de vaccination est fortement recommandée, particulièrement pour les jeunes animaux et lors de la transition des saisons. Contactez votre vétérinaire local pour prendre un rendez-vous et en savoir plus sur les tarifs. La vaccination préventive coûte moins cher que le traitement des maladies.",
            "imageUrl": None,
            "pubDate": datetime.now().isoformat(),
            "source": "Vétérinaire",
            "category": "Santé animale",
        },
    ]
