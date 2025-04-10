import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:buapnet/presentation/providers/auth_provider.dart';
import 'package:buapnet/presentation/providers/post_provider.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  final List<String> _tags = [];
  final List<File> _mediaFiles = [];
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  // Seleccionar imagen de la galería
  Future<void> _pickImage() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _mediaFiles.addAll(images.map((image) => File(image.path)));
      });
    }
  }

  // Tomar foto con la cámara
  Future<void> _takePicture() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _mediaFiles.add(File(image.path));
      });
    }
  }

  // Eliminar un archivo multimedia
  void _removeMedia(int index) {
    setState(() {
      _mediaFiles.removeAt(index);
    });
  }

  // Añadir una etiqueta
  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  // Eliminar una etiqueta
  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  // Crear publicación
  Future<void> _createPost() async {
    if (_contentController.text.trim().isEmpty && _mediaFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La publicación no puede estar vacía'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final postProvider = Provider.of<PostProvider>(context, listen: false);

    final userId = authProvider.user?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Usuario no autenticado'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isSubmitting = false;
      });
      return;
    }

    final success = await postProvider.createPost(
      userId: userId,
      content: _contentController.text.trim(),
      mediaFiles: _mediaFiles.isNotEmpty ? _mediaFiles : null,
      tags: _tags.isNotEmpty ? _tags : null,
    );

    setState(() {
      _isSubmitting = false;
    });

    if (success && mounted) {
      _contentController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _mediaFiles.isNotEmpty 
                ? 'Publicación enviada para aprobación' 
                : 'Publicación creada exitosamente'
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(postProvider.error ?? 'Error al crear la publicación'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva publicación'),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _createPost,
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Publicar'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera con avatar y nombre
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                  backgroundImage: user?.avatarBase64 != null && user!.avatarBase64.isNotEmpty
                      ? NetworkImage(user.avatarBase64)
                      : null,
                  child: user?.avatarBase64 == null || user!.avatarBase64.isEmpty
                      ? Text(
                          user?.username != null && user!.username.isNotEmpty
                              ? user.username[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Text(
                  user?.username ?? 'Usuario',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Campo de texto para el contenido
            TextField(
              controller: _contentController,
              maxLines: 8,
              decoration: const InputDecoration(
                hintText: '¿Qué quieres compartir con la comunidad?',
                border: InputBorder.none,
              ),
            ),
            
            // Mostrar imágenes seleccionadas
            if (_mediaFiles.isNotEmpty) ...[
              const Divider(),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _mediaFiles.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: FileImage(_mediaFiles[index]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 12,
                          child: GestureDetector(
                            onTap: () => _removeMedia(index),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
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
            ],
            
            const Divider(),
            
            // Etiquetas
            if (_tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _tags.map((tag) {
                  return Chip(
                    label: Text('#$tag'),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => _removeTag(tag),
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
            ],
            
            // Añadir etiqueta
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagController,
                    decoration: const InputDecoration(
                      hintText: 'Añadir etiqueta',
                      prefixIcon: Icon(Icons.tag),
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                    ),
                    onSubmitted: (_) => _addTag(),
                  ),
                ),
                IconButton(
                  onPressed: _addTag,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Botones para añadir media
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildMediaButton(
                  icon: Icons.photo_library,
                  label: 'Galería',
                  onTap: _pickImage,
                ),
                _buildMediaButton(
                  icon: Icons.camera_alt,
                  label: 'Cámara',
                  onTap: _takePicture,
                ),
              ],
            ),
            
            // Advertencia sobre moderación
            if (_mediaFiles.isNotEmpty) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Las publicaciones con imágenes requieren aprobación de un moderador antes de ser visibles.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMediaButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28),
            const SizedBox(height: 4),
            Text(label),
          ],
        ),
      ),
    );
  }
}