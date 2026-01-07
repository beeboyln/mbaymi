from typing import Optional

class AdviceService:
    """
    Service pour générer des conseils automatiques pour l'agriculture et l'élevage
    sans IA - basé sur des règles prédéfinies
    """
    
    CROP_ADVICE = {
        "maïs": {
            "title": "Guide de culture du maïs",
            "advice": "Le maïs nécessite un sol riche en nutriments et une bonne irrigation. Plantez en saison des pluies pour un meilleur rendement.",
            "tips": [
                "Préparez le sol 2-3 semaines avant de planter",
                "Espacez les plants de 25-30cm",
                "Arrosez régulièrement, surtout pendant la floraison",
                "Appliquez un engrais NPK riche en azote",
                "Récoltez 3-4 mois après la plantation"
            ],
            "warnings": ["Attention aux ravageurs: moucherons du maïs", "Assurez-vous d'une bonne drainage"]
        },
        "riz": {
            "title": "Guide de culture du riz",
            "advice": "Le riz a besoin d'une submersion régulière. Un pH du sol entre 6 et 7 est optimal.",
            "tips": [
                "Préparez les lits de semis longtemps à l'avance",
                "Maintenez 5-10cm d'eau sur le champ pendant la croissance",
                "Appliquez de l'engrais composé tous les 15 jours",
                "Luttez contre les mauvaises herbes régulièrement",
                "Récoltez quand 80-90% des grains sont matures"
            ],
            "warnings": ["Prévenez la pourriture des tiges", "Contrôlez les criquets"]
        },
        "arachide": {
            "title": "Guide de culture de l'arachide",
            "advice": "L'arachide préfère un sol sableux. Elle a besoin de 120-150 jours pour arriver à maturité.",
            "tips": [
                "Semez après les premières pluies",
                "Espacez les plants de 15-20cm",
                "Le sol doit rester humide mais pas inondé",
                "Appliquez du calcium (chaux) pour éviter la carence",
                "Arrachez quand les feuilles commencent à jaunir"
            ],
            "warnings": ["Attention à l'aflatoxine en stockage", "Prévenez le pourrissement des gousses"]
        },
        "millet": {
            "title": "Guide de culture du millet",
            "advice": "Le millet est très résistant à la sécheresse. C'est une culture idéale pour les régions arides.",
            "tips": [
                "Semez en début de saison des pluies",
                "Nécessite peu d'engrais",
                "Espacez les plants de 20-25cm",
                "Arrosez modérément",
                "Récoltez 60-90 jours après la plantation"
            ],
            "warnings": ["Attention aux oiseaux pendant la maturation", "Traitez les pucerons si nécessaire"]
        },
        "tomate": {
            "title": "Guide de culture de la tomate",
            "advice": "La tomate a besoin de soleil et de beaucoup d'eau. Un sol riche en matière organique est important.",
            "tips": [
                "Plantez en début de saison chaude",
                "Tuteurez les plants pour éviter qu'ils ne se cassent",
                "Arrosez profondément 2-3 fois par semaine",
                "Appliquez un engrais riche en phosphore et potassium",
                "Récoltez 60-80 jours après la plantation"
            ],
            "warnings": ["Attention au mildiou par temps humide", "Éliminez les feuilles malades"]
        }
    }
    
    LIVESTOCK_ADVICE = {
        "cattle": {
            "title": "Guide d'élevage du bétail",
            "advice": "Le bétail a besoin d'un accès régulier à l'eau et à une alimentation équilibrée. La vaccination régulière est essentielle.",
            "tips": [
                "Fournissez de l'eau propre au moins 2 fois par jour",
                "Alimentez avec du foin de qualité ou des pâturages verts",
                "Vaccinez contre les maladies courantes (fièvre aphteuse, charbon)",
                "Effectuez un contrôle vétérinaire mensuel",
                "Maintenez une bonne hygiène des enclos"
            ],
            "warnings": ["Attention à la fièvre aphteuse", "Prévenez les parasites externes"]
        },
        "goat": {
            "title": "Guide d'élevage des chèvres",
            "advice": "Les chèvres sont des animaux robustes mais ont besoin d'un abri adéquat et d'une alimentation diversifiée.",
            "tips": [
                "Fournissez un abri ventilé et sec",
                "Alimentez avec du foin, des grains et des pâturages",
                "Vaccinez contre la fièvre Q et autres maladies",
                "Trayez 2 fois par jour (femelles laitières)",
                "Examinez régulièrement les sabots et les cornes"
            ],
            "warnings": ["Attention à la gale", "Prévenez les entérocolites"]
        },
        "sheep": {
            "title": "Guide d'élevage des moutons",
            "advice": "Les moutons ont besoin de pâturages de qualité et d'un abri protégé. La tonte doit être régulière.",
            "tips": [
                "Assurez une alimentation riche en fibres",
                "Tondez une fois par an, généralement au printemps",
                "Vaccinez contre les maladies communes",
                "Fournissez un accès à l'eau propre à volonté",
                "Contrôlez les parasites internes 2-3 fois par an"
            ],
            "warnings": ["Attention à la gale sarcoptique", "Prévenez la pourriture des sabots"]
        },
        "poultry": {
            "title": "Guide d'élevage de la volaille",
            "advice": "La volaille a besoin de chaleur, d'eau et d'une alimentation équilibrée. L'hygiène est cruciale.",
            "tips": [
                "Maintenez la température à 35°C pour les poussins",
                "Fournissez une eau propre à volonté",
                "Alimentez avec un aliment équilibré (protéines 16-20%)",
                "Nettoyez le poulailler régulièrement",
                "Vaccinez contre Newcastle et les autres maladies"
            ],
            "warnings": ["Attention aux maladies respiratoires", "Prévenez la coccidiose"]
        },
        "pig": {
            "title": "Guide d'élevage des porcs",
            "advice": "Les porcs ont besoin d'un bon abri, d'eau propre et d'une alimentation riche en protéines.",
            "tips": [
                "Construisez une porcherie bien ventilée",
                "Fournissez de l'eau fraîche constamment",
                "Alimentez avec des aliments riches en protéines et minéraux",
                "Vaccinez contre la peste porcine africaine",
                "Maintenez un bon système de drainage"
            ],
            "warnings": ["Attention à la peste porcine africaine", "Prévenez les infections parasitaires"]
        }
    }
    
    def get_crop_advice(self, crop_name: str, region: Optional[str] = None) -> dict:
        """Obtenir des conseils pour une culture spécifique"""
        crop_lower = crop_name.lower()
        
        for crop_key, advice in self.CROP_ADVICE.items():
            if crop_key in crop_lower or crop_lower in crop_key:
                return {
                    "title": advice["title"],
                    "advice": advice["advice"],
                    "tips": advice["tips"],
                    "warnings": advice.get("warnings", [])
                }
        
        # Si la culture n'existe pas, retourner un conseil générique
        return {
            "title": f"Conseils pour {crop_name}",
            "advice": f"Nous n'avons pas de guide spécifique pour {crop_name}. Consultez un agent agricole local pour des conseils détaillés.",
            "tips": [
                "Préparez bien votre sol avant la plantation",
                "Assurez-vous une irrigation régulière",
                "Utilisez un engrais adapté à votre sol",
                "Nettoyez régulièrement vos champs",
                "Consultez les données météorologiques locales"
            ],
            "warnings": None
        }
    
    def get_livestock_advice(self, animal_type: str, region: Optional[str] = None) -> dict:
        """Obtenir des conseils pour un type d'animal spécifique"""
        animal_lower = animal_type.lower()
        
        for animal_key, advice in self.LIVESTOCK_ADVICE.items():
            if animal_key in animal_lower or animal_lower in animal_key:
                return {
                    "title": advice["title"],
                    "advice": advice["advice"],
                    "tips": advice["tips"],
                    "warnings": advice.get("warnings", [])
                }
        
        # Si l'animal n'existe pas, retourner un conseil générique
        return {
            "title": f"Conseils pour l'élevage de {animal_type}",
            "advice": f"Nous n'avons pas de guide spécifique pour {animal_type}. Consultez un vétérinaire local pour des conseils détaillés.",
            "tips": [
                "Fournissez un abri adéquat et propre",
                "Assurez un accès constant à l'eau propre",
                "Alimentez avec une nutrition équilibrée",
                "Vaccinez régulièrement",
                "Nettoyez et entretenez les enclos"
            ],
            "warnings": None
        }
