import 'package:flutter/material.dart';

enum TutorialPolicyType {
  tutorialNuevos,
  tutorialPublicar,
  politicasUsuarios,
  politicasPublicacion,
}

class TutorialPoliciesScreen extends StatefulWidget {
  final TutorialPolicyType type;

  const TutorialPoliciesScreen({super.key, required this.type});

  @override
  State<TutorialPoliciesScreen> createState() => _TutorialPoliciesScreenState();
}

class _TutorialPoliciesScreenState extends State<TutorialPoliciesScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Colores consistentes con tu marca
  final Color primaryColor = const Color(0xFFFF6B35);
  final Color darkColor = const Color(0xFF1E272E);

  String get _title {
    switch (widget.type) {
      case TutorialPolicyType.tutorialNuevos:
        return 'Guía de Inicio';
      case TutorialPolicyType.tutorialPublicar:
        return '¿Cómo publicar?';
      case TutorialPolicyType.politicasUsuarios:
        return 'Normas de Usuario';
      case TutorialPolicyType.politicasPublicacion:
        return 'Políticas de Publicación';
    }
  }

  List<Map<String, dynamic>> get _pages {
    switch (widget.type) {
      case TutorialPolicyType.tutorialNuevos:
        return [
          {
            'icon': Icons.account_circle_outlined,
            'title': 'Bienvenido a Llama-Market',
            'content':
                'Llama-Market es una plataforma diseñada para estudiantes de la ESPOCH donde podrás ofrecer y solicitar servicios de manera segura y sencilla.',
          },
          {
            'icon': Icons.search_rounded,
            'title': 'Explora Servicios',
            'content':
                'Utiliza la barra de búsqueda en la pantalla principal para encontrar servicios que necesites. Puedes filtrar por categoría y ubicación.',
          },
          {
            'icon': Icons.chat_bubble_outline_rounded,
            'title': 'Contacta Vendedores',
            'content':
                'Una vez encuentres un servicio de tu interés, puedes contactar directamente al vendedor mediante el sistema de mensajería integrado.',
          },
          {
            'icon': Icons.star_outline_rounded,
            'title': 'Califica y Opina',
            'content':
                'Después de completar una transacción, recuerda calificar al vendedor. Esto ayuda a mantener la confianza en la comunidad.',
          },
        ];

      case TutorialPolicyType.tutorialPublicar:
        return [
          {
            'icon': Icons.add_circle_outline_rounded,
            'title': 'Crear una Publicación',
            'content':
                'Toca el botón "+" en la barra de navegación inferior para crear una nueva publicación de servicio.',
          },
          {
            'icon': Icons.title_rounded,
            'title': 'Título Descriptivo',
            'content':
                'Escribe un título claro y descriptivo para tu servicio. Máximo 40 caracteres. Ejemplo: "Clases de Matemáticas" o "Vendo Apuntes de Física".',
          },
          {
            'icon': Icons.photo_camera_outlined,
            'title': 'Agrega Fotos',
            'content':
                'Puedes subir hasta 3 fotos de tu servicio o producto. Las imágenes de buena calidad atraen más compradores.',
          },
          {
            'icon': Icons.location_on_outlined,
            'title': 'Ubicación y Detalles',
            'content':
                'Indica dónde se encuentra tu servicio o producto. Proporciona una descripción detallada (máximo 2030 caracteres).',
          },
          {
            'icon': Icons.check_circle_outline_rounded,
            'title': 'Revisión de Contenido',
            'content':
                'Todas las publicaciones pasan por una revisión automática. Asegúrate de que tu contenido cumpla con nuestras políticas para evitar que sea marcada como inactiva.',
          },
        ];

      case TutorialPolicyType.politicasUsuarios:
        return [
          {
            'icon': Icons.verified_user_outlined,
            'title': 'Cuenta Verificada',
            'content':
                'Solo estudiantes con correo institucional (@espoch.edu.ec) pueden registrarse. Mantén tu información actualizada y verídica.',
          },
          {
            'icon': Icons.handshake_outlined,
            'title': 'Respeto y Cortesía',
            'content':
                'Trata a todos los usuarios con respeto. No se toleran insultos, acoso ni discriminación de ningún tipo.',
          },
          {
            'icon': Icons.report_gmailerrorred_rounded,
            'title': 'Reporta Actividad',
            'content':
                'Si encuentras contenido inapropiado o actividad sospechosa, repórtalo inmediatamente. Tu reporte es confidencial.',
          },
          {
            'icon': Icons.block_flipped,
            'title': 'Contenido Prohibido',
            'content':
                'Está prohibido publicar contenido sexual, violento o ilegal. Las cuentas que violen estas normas serán suspendidas permanentemente.',
          },
        ];

      case TutorialPolicyType.politicasPublicacion:
        return [
          {
            'icon': Icons.edit_note_rounded,
            'title': 'Información Precisa',
            'content':
                'Proporciona información precisa y honesta sobre tu servicio. Las descripciones engañosas pueden resultar en la eliminación de tu publicación.',
          },
          {
            'icon': Icons.photo_library_outlined,
            'title': 'Imágenes Apropiadas',
            'content':
                'Usa imágenes reales de tu servicio o producto. No se permiten imágenes con contenido sexual, violento o engañoso.',
          },
          {
            'icon': Icons.cancel_outlined,
            'title': 'Contenido No Permitido',
            'content':
                'No se permiten: servicios sexuales, drogas, armas, productos robados o trabajos académicos fraudulentos.',
          },
          {
            'icon': Icons.warning_amber_rounded,
            'title': 'Sistema de Reportes',
            'content':
                'Si una publicación recibe 5 o más reportes válidos, será automáticamente marcada como inactiva para su revisión.',
          },
          {
            'icon': Icons.update_rounded,
            'title': 'Mantén la Vigencia',
            'content':
                'Si tu servicio ya no está disponible, elimina la publicación. Las publicaciones desactualizadas afectan tu calificación.',
          },
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = _pages;
    final bool isLastPage = _currentPage == pages.length - 1;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Fondo con gradiente sutil
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primaryColor.withOpacity(0.12),
                    Colors.white,
                    primaryColor.withOpacity(0.05),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const BouncingScrollPhysics(),
                    onPageChanged: (index) =>
                        setState(() => _currentPage = index),
                    itemCount: pages.length,
                    itemBuilder: (context, index) {
                      return _buildPageCard(
                        pages[index]['icon'] as IconData,
                        pages[index]['title'] as String,
                        pages[index]['content'] as String,
                      );
                    },
                  ),
                ),
                _buildFooter(pages.length, isLastPage),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            _title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: darkColor,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageCard(IconData icon, String title, String content) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icono con capas de sombra y color
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 160,
                width: 160,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
              ),
              Icon(icon, size: 80, color: primaryColor),
            ],
          ),
          const SizedBox(height: 50),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: darkColor,
              height: 1.1,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              content,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                color: Colors.blueGrey[700],
                height: 1.6,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(int pageCount, bool isLastPage) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        children: [
          // Indicadores Minimalistas
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              pageCount,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == index ? 28 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? primaryColor
                      : primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          // Botón estilizado
          SizedBox(
            width: double.infinity,
            height: 64,
            child: ElevatedButton(
              onPressed: () {
                if (isLastPage) {
                  Navigator.pop(context);
                } else {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeInOutQuart,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                elevation: 8,
                shadowColor: primaryColor.withOpacity(0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  isLastPage ? "COMENZAR" : "SIGUIENTE",
                  key: ValueKey(isLastPage),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
