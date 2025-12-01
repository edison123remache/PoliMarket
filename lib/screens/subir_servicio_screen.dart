import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/location_service.dart';

class SubirServicioScreen extends StatefulWidget {
  const SubirServicioScreen({super.key});

  @override
  State<SubirServicioScreen> createState() => _SubirServicioScreenState();
}

class _SubirServicioScreenState extends State<SubirServicioScreen> {
  final List<File> _fotos = [];
  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _ubicacionController = TextEditingController();

  bool _isLoading = false;
  bool _showUbicacionDialog = false;

  final ImagePicker _picker = ImagePicker();

  // Tomar foto con cámara
  Future<void> _tomarFoto() async {
    if (_fotos.length >= 3) {
      _mostrarError('Máximo 3 fotos permitidas');
      return;
    }

    try {
      final XFile? foto = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );

      if (foto != null) {
        setState(() {
          _fotos.add(File(foto.path));
        });
      }
    } catch (e) {
      _mostrarError('Error al tomar foto: $e');
    }
  }

  // Diálogo para seleccionar origen de foto
  void _mostrarOpcionesFoto() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galería'),
              onTap: () {
                Navigator.pop(context);
                _seleccionarFotos();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Cámara'),
              onTap: () {
                Navigator.pop(context);
                _tomarFoto();
              },
            ),
          ],
        ),
      ),
    );
  }

  // Seleccionar fotos de la galería
  Future<void> _seleccionarFotos() async {
    if (_fotos.length >= 3) {
      _mostrarError('Máximo 3 fotos permitidas');
      return;
    }

    try {
      final List<XFile> selectedImages = await _picker.pickMultiImage(
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );

      if (selectedImages != null) {
        int availableSlots = 3 - _fotos.length;
        int imagesToAdd = selectedImages.length > availableSlots
            ? availableSlots
            : selectedImages.length;

        for (int i = 0; i < imagesToAdd; i++) {
          _fotos.add(File(selectedImages[i].path));
        }

        setState(() {});
      }
    } catch (e) {
      _mostrarError('Error al seleccionar imágenes: $e');
    }
  }

  // Eliminar foto
  void _eliminarFoto(int index) {
    setState(() {
      _fotos.removeAt(index);
    });
  }

  // Obtener ubicación automática
  Future<void> _obtenerUbicacionAutomatica() async {
    setState(() => _isLoading = true);

    try {
      final position = await LocationServiceIQ.getCurrentLocation();
      final address = await LocationServiceIQ.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      setState(() {
        _ubicacionController.text = address;
        _showUbicacionDialog = false;
      });
    } catch (e) {
      _mostrarError('Error al obtener ubicación: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Guardar ubicación personalizada
  void _guardarUbicacionPersonalizada() {
    if (_ubicacionController.text.trim().isEmpty) {
      _mostrarError('Por favor ingresa una ubicación');
      return;
    }

    if (_ubicacionController.text.length > 100) {
      _mostrarError('La ubicación no puede tener más de 100 caracteres');
      return;
    }

    setState(() {
      _showUbicacionDialog = false;
    });
  }

  // Subir fotos a Supabase Storage
  Future<List<String>> _subirFotos() async {
    List<String> fotoUrls = [];
    final supabase = Supabase.instance.client;

    for (var foto in _fotos) {
      final fileName =
          'servicios/${DateTime.now().millisecondsSinceEpoch}_${foto.path.split('/').last}';

      try {
        await supabase.storage.from('service-photos').upload(fileName, foto);

        final publicUrl = supabase.storage
            .from('service-photos')
            .getPublicUrl(fileName);

        fotoUrls.add(publicUrl);
      } catch (e) {
        throw Exception('Error al subir foto: $e');
      }
    }

    return fotoUrls;
  }

  // Guardar servicio en la base de datos
  Future<void> _guardarServicio() async {
    // Validaciones
    if (_fotos.isEmpty) {
      _mostrarError('Agrega al menos una foto');
      return;
    }

    if (_tituloController.text.trim().isEmpty) {
      _mostrarError('El título es requerido');
      return;
    }

    if (_descripcionController.text.trim().isEmpty) {
      _mostrarError('La descripción es requerida');
      return;
    }

    if (_ubicacionController.text.trim().isEmpty) {
      _mostrarError('La ubicación es requerida');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Subir fotos
      final fotoUrls = await _subirFotos();

      // 2. Obtener usuario actual
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) throw Exception('Usuario no autenticado');

      // 3. Insertar servicio en la base de datos
      await supabase.from('servicios').insert({
        'user_id': user.id,
        'titulo': _tituloController.text.trim(),
        'descripcion': _descripcionController.text.trim(),
        'ubicacion': _ubicacionController.text.trim(),
        'fotos': fotoUrls,
        'status': 'activa',
        'numero_de_reportes': 0,
      });

      // 4. Éxito - regresar
      Navigator.pop(context);
    } catch (e) {
      _mostrarError('Error al guardar servicio: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
    );
  }

  void _cancelar() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subir Post')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildForm(),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SECCIÓN FOTOS
          _buildSeccionFotos(),
          const SizedBox(height: 24),

          // SECCIÓN TÍTULO
          _buildSeccionTitulo(),
          const SizedBox(height: 20),

          // SECCIÓN DESCRIPCIÓN
          _buildSeccionDescripcion(),
          const SizedBox(height: 20),

          // SECCIÓN UBICACIÓN
          _buildSeccionUbicacion(),
          const SizedBox(height: 24),

          // TEXTO INFORMATIVO
          _buildTextoInformativo(),
          const SizedBox(height: 24),

          // BOTONES
          _buildBotones(),
        ],
      ),
    );
  }

  Widget _buildSeccionFotos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Agregar Fotos',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          '${_fotos.length}/3',
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
        const SizedBox(height: 12),

        // Grid de fotos
        SizedBox(
          height: 120,
          child: Row(
            children: [
              // Fotos existentes
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _fotos.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: FileImage(_fotos[index]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 16,
                          child: GestureDetector(
                            onTap: () => _eliminarFoto(index),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Botón agregar
              if (_fotos.length < 3)
                GestureDetector(
                  onTap: _mostrarOpcionesFoto,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey, width: 2),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey[100],
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate,
                          size: 32,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 8),
                        Text('Agregar', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSeccionTitulo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Título:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          '${_tituloController.text.length}/40',
          style: TextStyle(
            color: _tituloController.text.length > 40
                ? Colors.red
                : Colors.grey,
          ),
        ),
        TextField(
          controller: _tituloController,
          decoration: const InputDecoration(
            hintText: 'Ingrese Título de la publicación',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          ),
          maxLength: 40,
          onChanged: (value) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildSeccionDescripcion() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Descripción:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          '${_descripcionController.text.length}/2030',
          style: TextStyle(
            color: _descripcionController.text.length > 2030
                ? Colors.red
                : Colors.grey,
          ),
        ),
        TextField(
          controller: _descripcionController,
          decoration: const InputDecoration(
            hintText: 'Ingrese Descripción de la publicación',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          ),
          maxLength: 2030,
          maxLines: 5,
          onChanged: (value) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildSeccionUbicacion() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ubicación:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            setState(() {
              _showUbicacionDialog = true;
            });
          },
          child: AbsorbPointer(
            child: TextField(
              controller: _ubicacionController,
              decoration: const InputDecoration(
                hintText: 'Ingrese Ubicación de la publicación',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.location_on),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
              ),
            ),
          ),
        ),

        // Diálogo de ubicación
        if (_showUbicacionDialog) _buildUbicacionDialog(),
      ],
    );
  }

  Widget _buildUbicacionDialog() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue),
        borderRadius: BorderRadius.circular(12),
        color: Colors.blue[50],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Seleccionar Ubicación',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 16),

          // Ubicación personalizada
          const Text(
            'Ubicación Personalizada:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _ubicacionController,
            decoration: const InputDecoration(
              hintText: 'Escriba aquí',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
            maxLength: 100,
          ),
          const SizedBox(height: 16),

          // O usar ubicación automática
          const Text(
            'O usar mi ubicación actual:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _obtenerUbicacionAutomatica,
            icon: const Icon(Icons.my_location),
            label: const Text('Localizarme'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          // Botones de acción
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _guardarUbicacionPersonalizada,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Aceptar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _showUbicacionDialog = false;
                    });
                  },
                  child: const Text('Cancelar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextoInformativo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange),
      ),
      child: RichText(
        text: const TextSpan(
          style: TextStyle(color: Colors.black87, fontSize: 14),
          children: [
            TextSpan(
              text: 'Antes de que los usuarios accedan a tu publicación ',
            ),
            TextSpan(
              text: 'recuerda que las publicaciones se someten a revisiones ',
            ),
            TextSpan(
              text:
                  'que de ser infringidas pueden afectar el estado de tu cuenta. ',
            ),
            TextSpan(text: 'Para más información consulta nuestra '),
            TextSpan(
              text: 'Política de Publicación',
              style: TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBotones() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _guardarServicio,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Subir', style: TextStyle(fontSize: 16)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton(
            onPressed: _cancelar,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: Colors.grey),
            ),
            child: const Text(
              'Cancelar',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
        ),
      ],
    );
  }
}