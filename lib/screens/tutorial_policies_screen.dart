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

  String get _title {
    switch (widget.type) {
      case TutorialPolicyType.tutorialNuevos:
        return 'Tutorial para Usuarios Nuevos';
      case TutorialPolicyType.tutorialPublicar:
        return 'Tutorial para Publicar Servicio';
      case TutorialPolicyType.politicasUsuarios:
        return 'Políticas para Usuarios';
      case TutorialPolicyType.politicasPublicacion:
        return 'Políticas de Publicación';
    }
  }

  List<Map<String, dynamic>> get _pages {
    switch (widget.type) {
      case TutorialPolicyType.tutorialNuevos:
        return [
          {
            'icon': Icons.account_circle,
            'title': 'Bienvenido a PoliMarket',
            'content':
                'PoliMarket es una plataforma diseñada para estudiantes de la ESPOCH donde podrás ofrecer y solicitar servicios de manera segura y sencilla.',
          },
          {
            'icon': Icons.search,
            'title': 'Explora Servicios',
            'content':
                'Utiliza la barra de búsqueda en la pantalla principal para encontrar servicios que necesites. Puedes filtrar por categoría y ubicación.',
          },
          {
            'icon': Icons.chat,
            'title': 'Contacta Vendedores',
            'content':
                'Una vez encuentres un servicio de tu interés, puedes contactar directamente al vendedor mediante el sistema de mensajería integrado.',
          },
          {
            'icon': Icons.star,
            'title': 'Califica y Opina',
            'content':
                'Después de completar una transacción, recuerda calificar al vendedor. Esto ayuda a mantener la confianza en la comunidad.',
          },
        ];

      case TutorialPolicyType.tutorialPublicar:
        return [
          {
            'icon': Icons.add_circle,
            'title': 'Crear una Publicación',
            'content':
                'Toca el botón "+" en la barra de navegación inferior para crear una nueva publicación de servicio.',
          },
          {
            'icon': Icons.title,
            'title': 'Título Descriptivo',
            'content':
                'Escribe un título claro y descriptivo para tu servicio. Máximo 40 caracteres. Ejemplo: "Clases de Matemáticas" o "Vendo Apuntes de Física".',
          },
          {
            'icon': Icons.photo_camera,
            'title': 'Agrega Fotos',
            'content':
                'Puedes subir hasta 3 fotos de tu servicio o producto. Las imágenes de buena calidad atraen más compradores.',
          },
          {
            'icon': Icons.location_on,
            'title': 'Ubicación y Detalles',
            'content':
                'Indica dónde se encuentra tu servicio o producto. Proporciona una descripción detallada (máximo 2030 caracteres).',
          },
          {
            'icon': Icons.check_circle,
            'title': 'Revisión de Contenido',
            'content':
                'Todas las publicaciones pasan por una revisión automática. Asegúrate de que tu contenido cumpla con nuestras políticas para evitar que sea marcada como inactiva.',
          },
        ];

      case TutorialPolicyType.politicasUsuarios:
        return [
          {
            'icon': Icons.verified_user,
            'title': 'Cuenta Verificada',
            'content':
                'Solo estudiantes con correo institucional (@espoch.edu.ec) pueden registrarse. Mantén tu información actualizada y verídica.',
          },
          {
            'icon': Icons.handshake,
            'title': 'Respeto y Cortesía',
            'content':
                'Trata a todos los usuarios con respeto. No se toleran insultos, acoso ni discriminación de ningún tipo. Cualquier comportamiento inapropiado puede resultar en suspensión.',
          },
          {
            'icon': Icons.security,
            'title': 'Transacciones Seguras',
            'content':
                'Realiza transacciones en lugares públicos y seguros dentro del campus. PoliMarket no se hace responsable de transacciones fuera de la plataforma.',
          },
          {
            'icon': Icons.report,
            'title': 'Reporta Actividad Sospechosa',
            'content':
                'Si encuentras contenido inapropiado o actividad sospechosa, repórtalo inmediatamente. Tu reporte es confidencial y nos ayuda a mantener la comunidad segura.',
          },
          {
            'icon': Icons.block,
            'title': 'Contenido Prohibido',
            'content':
                'Está prohibido publicar contenido sexual, violento, discriminatorio o que promueva actividades ilegales. Las cuentas que violen estas normas serán suspendidas permanentemente.',
          },
        ];

      case TutorialPolicyType.politicasPublicacion:
        return [
          {
            'icon': Icons.edit_note,
            'title': 'Información Precisa',
            'content':
                'Proporciona información precisa y honesta sobre tu servicio o producto. Las descripciones engañosas pueden resultar en la eliminación de tu publicación.',
          },
          {
            'icon': Icons.attach_money,
            'title': 'Precios Justos',
            'content':
                'Establece precios razonables y justos. Las publicaciones con precios excesivamente altos pueden ser reportadas y revisadas.',
          },
          {
            'icon': Icons.photo_library,
            'title': 'Imágenes Apropiadas',
            'content':
                'Usa imágenes reales de tu servicio o producto. No se permiten imágenes con contenido sexual, violento o engañoso.',
          },
          {
            'icon': Icons.cancel,
            'title': 'Contenido No Permitido',
            'content':
                'No se permiten publicaciones de: servicios sexuales, drogas, armas, productos robados, trabajos académicos fraudulentos (hacer tareas por otros), o cualquier actividad ilegal.',
          },
          {
            'icon': Icons.warning,
            'title': 'Sistema de Reportes',
            'content':
                'Si una publicación recibe 5 o más reportes válidos, será automáticamente marcada como inactiva y revisada por administradores. Mantén tu contenido dentro de las normas.',
          },
          {
            'icon': Icons.update,
            'title': 'Mantén tu Publicación Actualizada',
            'content':
                'Si tu servicio o producto ya no está disponible, elimina la publicación. Las publicaciones desactualizadas afectan negativamente tu calificación.',
          },
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = _pages;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Header con botón de regreso
            _buildHeader(),

            // Contenido con carrusel
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(
                    pages[index]['icon'] as IconData,
                    pages[index]['title'] as String,
                    pages[index]['content'] as String,
                  );
                },
              ),
            ),

            // Indicadores de página (dots)
            _buildPageIndicators(pages.length),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Botón de regreso
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF2D3436)),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 12),
          // Título
          Expanded(
            child: Text(
              _title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3436),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(IconData icon, String title, String content) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icono
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFFFFB088).withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFF6B35), width: 3),
            ),
            child: Icon(icon, size: 80, color: const Color(0xFFFF6B35)),
          ),

          const SizedBox(height: 32),

          // Título
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3436),
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          // Contenido
          Text(
            content,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicators(int pageCount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        pageCount,
        (index) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentPage == index ? 32 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentPage == index
                ? const Color(0xFFFF6B35)
                : const Color(0xFFFFB088).withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}
