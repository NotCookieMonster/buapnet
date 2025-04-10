// lib/presentation/screens/profile/edit_profile_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:buapnet/presentation/providers/auth_provider.dart';
import 'package:buapnet/presentation/providers/user_provider.dart';
import 'package:buapnet/services/image_service.dart';
import 'package:buapnet/presentation/widgets/user_avatar_widget.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _facultyController;
  File? _imageFile;
  String? _currentAvatarBase64;
  bool _isLoading = false;
  bool _usernameAvailable = true;
  
  final List<String> _faculties = [
    'Facultad de Ciencias de la Computación',
    'Facultad de Ciencias Físico Matemáticas',
    'Facultad de Ingeniería',
    'Facultad de Administración',
    'Facultad de Contaduría Pública',
    'Facultad de Derecho',
    'Facultad de Medicina',
    // Otras facultades de la BUAP...
  ];
  
  @override
  void initState() {
    super.initState();
    
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    
    // Inicializar controladores con datos actuales
    _usernameController = TextEditingController(text: user?.username ?? '');
    _firstNameController = TextEditingController(text: user?.firstName ?? '');
    _lastNameController = TextEditingController(text: user?.lastName ?? '');
    _facultyController = TextEditingController(text: user?.faculty ?? '');
    
    // Guardar avatar actual
    _currentAvatarBase64 = user?.avatarBase64;
  }
  
  @override
  void dispose() {
    _usernameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _facultyController.dispose();
    super.dispose();
  }
  
  // Seleccionar imagen de perfil
  Future<void> _selectImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(source: source);
      
      if (pickedFile != null) {
        // Recortar imagen
        final croppedFile = await _cropImage(File(pickedFile.path));
        
        if (croppedFile != null) {
          setState(() {
            _imageFile = croppedFile;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  // Recortar imagen
  Future<File?> _cropImage(File imageFile) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressQuality: 70,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Recortar imagen',
            toolbarColor: Theme.of(context).colorScheme.primary,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Recortar imagen',
            aspectRatioLockEnabled: true,
            aspectRatioPickerButtonHidden: true,
          ),
        ],
      );
      
      return croppedFile != null ? File(croppedFile.path) : null;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al recortar: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }
  
  // Mostrar opciones para seleccionar imagen
  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galería'),
                onTap: () {
                  Navigator.pop(context);
                  _selectImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Cámara'),
                onTap: () {
                  Navigator.pop(context);
                  _selectImage(ImageSource.camera);
                },
              ),
              if (_imageFile != null || _currentAvatarBase64?.isNotEmpty == true)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Eliminar foto'),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _imageFile = null;
                      _currentAvatarBase64 = "";
                    });
                  },
                ),
            ],
          ),
        );
      },
    );
  }
  
  // Verificar disponibilidad de username
  Future<void> _checkUsernameAvailability(String username) async {
    if (username.isEmpty) {
      setState(() {
        _usernameAvailable = false;
      });
      return;
    }
    
    if (username == Provider.of<AuthProvider>(context, listen: false).user?.username) {
      setState(() {
        _usernameAvailable = true;
      });
      return;
    }
    
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    setState(() {
      _isLoading = true;
    });
    
    final available = await userProvider.isUsernameAvailable(
      username,
      authProvider.user?.uid ?? '',
    );
    
    setState(() {
      _usernameAvailable = available;
      _isLoading = false;
    });
  }
  
  // Guardar cambios
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.uid;
      
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }
      
      // Procesar avatar si ha cambiado
      String? avatarBase64;
      if (_imageFile != null) {
        // Usar ImageService para codificar a base64
        final imageService = ImageService();
        avatarBase64 = await imageService.encodeImageToBase64(
          _imageFile!,
          quality: 60,
          maxWidth: 300,
          maxHeight: 300,
        );
      } else if (_currentAvatarBase64 == "") {
        // Si el usuario eliminó el avatar actual
        avatarBase64 = "";
      }
      
      // Actualizar perfil
      final success = await authProvider.updateUserProfile(
        username: _usernameController.text,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        faculty: _facultyController.text,
        avatarfile: avatarfile
      );
      
      setState(() {
        _isLoading = false;
      });
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil actualizado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error ?? 'Error al actualizar perfil'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    final user = authProvider.user;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Guardar'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar con soporte para Base64
              GestureDetector(
                onTap: _showImagePicker,
                child: Stack(
                  children: [
                    // Vista previa de la imagen seleccionada o la actual
                    _imageFile != null
                        ? CircleAvatar(
                            radius: 50,
                            backgroundImage: FileImage(_imageFile!),
                            backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                          )
                        : UserAvatarWidget(
                            base64Image: _currentAvatarBase64,
                            username: user?.username ?? '',
                            radius: 50,
                          ),
                    
                    // Icono de edición
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Datos de perfil
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Nombre de usuario',
                  hintText: 'Este nombre será visible para todos',
                  prefixIcon: const Icon(Icons.alternate_email),
                  suffixIcon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : _usernameAvailable
                          ? const Icon(Icons.check, color: Colors.green)
                          : const Icon(Icons.close, color: Colors.red),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa un nombre de usuario';
                  }
                  if (!_usernameAvailable) {
                    return 'Este nombre de usuario ya está en uso';
                  }
                  if (value.length < 4) {
                    return 'El nombre debe tener al menos 4 caracteres';
                  }
                  return null;
                },
                onChanged: (value) {
                  _checkUsernameAvailability(value);
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre(s)',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa tu nombre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Apellidos',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa tus apellidos';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Facultad (Dropdown)
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Facultad',
                  prefixIcon: Icon(Icons.school),
                ),
                value: _facultyController.text.isNotEmpty ? _facultyController.text : null,
                items: _faculties.map((String faculty) {
                  return DropdownMenuItem<String>(
                    value: faculty,
                    child: Text(
                      faculty,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _facultyController.text = newValue;
                    });
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Selecciona tu facultad';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              // Nota sobre visibilidad
              Container(
                padding: const EdgeInsets.all(16),
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
                        'Solo tu nombre de usuario y foto de perfil serán visibles para otros estudiantes. El resto de la información solo la pueden ver los moderadores.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}