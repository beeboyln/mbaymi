import 'package:flutter/material.dart';
import 'package:mbaymi/models/news_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mbaymi/utils/app_colors.dart';

class NewsDetailScreen extends StatelessWidget {
  final NewsArticle article;
  final bool? isDarkMode;

  const NewsDetailScreen({
    super.key,
    required this.article,
    this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = isDarkMode ?? 
        (Theme.of(context).brightness == Brightness.dark);
    final primaryColor = isDark ? const Color(0xFF4CAF50) : const Color(0xFF2D5016);
    final backgroundColor = isDark ? const Color(0xFF121212) : const Color(0xFFFAFAFA);
    final surfaceColor = isDark ? const Color(0xFF1E1E1E) : AppColors.lightBg;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final secondaryTextColor = isDark ? Colors.grey[400] : Colors.grey[700];

    return Scaffold(
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        slivers: [
          // AppBar avec image en arrière-plan
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: surfaceColor.withOpacity(0.95),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: primaryColor,
                    size: 22,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: surfaceColor.withOpacity(0.95),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.share_rounded,
                      color: primaryColor,
                      size: 22,
                    ),
                    onPressed: () => _shareArticle(article),
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeroImage(article, isDark),
            ),
          ),

          // Contenu de l'article
          SliverToBoxAdapter(
            child: Container(
              color: surfaceColor,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Catégorie - minimaliste
                    Text(
                      article.category?.toUpperCase() ?? 'AGRICULTURE',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Titre
                    Text(
                      article.title,
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w300,
                          height: 1.2,
                          color: textColor,
                          letterSpacing: -0.3,
                        ),
                    ),
                    const SizedBox(height: 32),

                    // Métadonnées minimalistes
                    Padding(
                      padding: const EdgeInsets.only(bottom: 32),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PAR',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: secondaryTextColor,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                article.source ?? 'Source non spécifiée',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'DATE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: secondaryTextColor,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                article.timeAgo,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Séparateur élégant
                    Padding(
                      padding: const EdgeInsets.only(bottom: 40),
                      child: Container(
                        height: 1,
                        color: isDark ? Colors.grey[800] : Colors.grey[200],
                      ),
                    ),

                    // Article principal - Style bibliothèque
                    SelectableText(
                      article.content ?? article.description,
                      style: TextStyle(
                        fontSize: 17,
                        height: 2.0,
                        color: textColor,
                        letterSpacing: 0.3,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Section lecture complémentaire
                    if (article.link != null && article.link!.isNotEmpty)
                      Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.06),
                                border: Border(
                                  top: BorderSide(
                                    color: primaryColor.withOpacity(0.3),
                                  ),
                                  bottom: BorderSide(
                                    color: primaryColor.withOpacity(0.3),
                                  ),
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'CONTINUER LA LECTURE',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: primaryColor,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Accédez à l\'article original sur la source pour consulter la version complète et intégrale.',
                                    style: TextStyle(
                                      fontSize: 14,
                                      height: 1.7,
                                      color: secondaryTextColor,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 48,
                                    child: ElevatedButton(
                                      onPressed: () => _launchUrl(article.link!),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primaryColor,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.zero,
                                        ),
                                      ),
                                      child: const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.open_in_new_rounded,
                                            size: 18,
                                          ),
                                          SizedBox(width: 10),
                                          Text(
                                            'LIRE L\'ARTICLE COMPLET',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => _shareArticle(article),
                            icon: Icon(
                              Icons.share_rounded,
                              color: primaryColor,
                              size: 18,
                            ),
                            label: Text(
                              'Partager',
                              style: TextStyle(
                                color: primaryColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),

                    // Footer informatif
                    Container(
                      padding: const EdgeInsets.only(top: 32),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'INFORMATIONS',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: secondaryTextColor,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Catégorie : ${article.category?.toUpperCase() ?? "AGRICULTURE"}',
                            style: TextStyle(
                              fontSize: 13,
                              color: textColor.withOpacity(0.8),
                              height: 1.8,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          Text(
                            'Source : ${article.source ?? "Non spécifiée"}',
                            style: TextStyle(
                              fontSize: 13,
                              color: textColor.withOpacity(0.8),
                              height: 1.8,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          Text(
                            'Publié ${article.timeAgo}',
                            style: TextStyle(
                              fontSize: 13,
                              color: secondaryTextColor,
                              height: 1.8,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroImage(NewsArticle article, bool isDark) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (article.imageUrl != null)
          Image.network(
            article.imageUrl!,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: isDark ? Colors.grey[900] : Colors.grey[200],
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF2D5016),
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                decoration: BoxDecoration(
                  image: const DecorationImage(
                    image: AssetImage('assets/images/d.jpg'),
                    fit: BoxFit.cover,
                  ),
                  gradient: LinearGradient(
                    colors: isDark
                        ? [Colors.grey[900]!, Colors.grey[800]!]
                        : [const Color(0xFF2D5016).withOpacity(0.0), const Color(0xFF4CAF50).withOpacity(0.0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              );
            },
          )
          else
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/d.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
        // Gradient overlay
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.4),
                Colors.black.withOpacity(0.7),
              ],
              stops: const [0.3, 0.7, 1.0],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
          webViewConfiguration: const WebViewConfiguration(
            enableJavaScript: true,
            enableDomStorage: true,
          ),
        );
      } else {
        throw 'Impossible d\'ouvrir l\'URL';
      }
    } catch (e) {
      print('Error launching URL: $e');
      // Vous pourriez afficher un Snackbar d'erreur ici
    }
  }

  Future<void> _shareArticle(NewsArticle article) async {
    final text = '${article.title}\n\n${article.link ?? ''}';
    // Utilisez un package de partage comme share_plus si disponible
    // await Share.share(text);
    print('Share article: $text');
  }
}