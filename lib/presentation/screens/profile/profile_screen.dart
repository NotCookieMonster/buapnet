import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:buapnet/data/models/user_model.dart';
import 'package:buapnet/presentation/providers/auth_provider.dart';
import 'package:buapnet/presentation/providers/post_provider.dart';
import 'package:buapnet/presentation/providers/user_provider.dart';
import 'package:buapnet/presentation/widgets/post_card.dart';
import 'package:buapnet/presentation/widgets/user_avatar_widget.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;
  
  const ProfileScreen({
    super.key,
    required this.userId,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Cargar datos del perfil
      if (widget.userId.isNotEmpty) {
        Provider.of<UserProvider>(context, listen: false)
            .getUserProfile(widget.userId);
        Provider.of<PostProvider>(context, listen: false)
            .initUserPosts(widget.userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final postProvider = Provider.of<PostProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    
    final bool isCurrentUser = authProvider.user?.uid == widget.userId;
    final UserModel? profileUser = isCurrentUser 
        ? authProvider.user 
        : userProvider.userProfile;
    final bool isLoading = userProvider.isLoading || 
                          (postProvider.isLoading && postProvider.userPosts.isEmpty);
    
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (profileUser == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Usuario no encontrado',
              style: theme.textTheme.titleLarge,
            ),
            if (userProvider.error != null) ...[
              const SizedBox(height: 8),
              Text(
                userProvider.error!,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      );
    }
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera de perfil
          _buildProfileHeader(profileUser, isCurrentUser, context),
          
          const Divider(),
          
          // Publicaciones del usuario
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Publicaciones',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          if (postProvider.userPosts.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('No hay publicaciones para mostrar'),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: postProvider.userPosts.length,
              itemBuilder: (context, index) {
                final post = postProvider.userPosts[index];
                return PostCard(
                  post: post,
                  currentUserId: authProvider.user?.uid ?? '',
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/post-detail',
                      arguments: post.id,
                    );
                  },
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(
    UserModel profileUser,
    bool isCurrentUser,
    BuildContext context,
  ) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar
          Hero(
          tag: 'profile-avatar-${profileUser.uid}',
          child: GestureDetector(
            onTap: isCurrentUser ? () {
              _showAvatarOptions(context, profileUser.uid);
            } : null,
            child: Stack(
              children: [
                UserAvatarWidget(
                  base64Image: profileUser.avatarBase64,
                  username: profileUser.username,
                  radius: 50,
                ),
                if (isCurrentUser)
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
        ),
          // Nombre de usuario
          Text(
            profileUser.username,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          if (profileUser.isModerator) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.verified,
                    size: 16,
                    color: theme.colorScheme.secondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Moderador',
                    style: TextStyle(
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // Facultad
          if (isCurrentUser && profileUser.faculty.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              profileUser.faculty,
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
          
          const SizedBox(height: 24),
          
          // Botones de acción
          if (isCurrentUser)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EditProfileScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.edit),
              label: const Text('Editar perfil'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 40),
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Botón de chat
                ElevatedButton.icon(
                  onPressed: () {
                    // Iniciar chat con este usuario
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          otherUserId: profileUser.uid,
                          otherUsername: profileUser.username,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat),
                  label: const Text('Mensaje'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(140, 40),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Botón de reportar (si no es moderador)
                if (!profileUser.isModerator)
                  OutlinedButton.icon(
                    onPressed: () {
                      _showReportUserDialog(context, profileUser);
                    },
                    icon: const Icon(Icons.flag),
                    label: const Text('Reportar'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(140, 40),
                    ),
                  ),
              ],
            ),
          
          const SizedBox(height: 8),
          
          // Botón de cerrar sesión (solo para usuario actual)
          if (isCurrentUser)
            TextButton.icon(
              onPressed: () {
                _showLogoutDialog(context, authProvider);
              },
              icon: const Icon(Icons.logout),
              label: const Text('Cerrar sesión'),
            ),
        ],
      ),
    );
  }
  
  // Diálogo de confirmación para cerrar sesión
  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cerrar sesión'),
          content: const Text('¿Estás seguro que deseas cerrar sesión?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                authProvider.signOut();
              },
              child: const Text('Cerrar sesión'),
            ),
          ],
        );
      },
    );
  }
  
  // Método para mostrar opciones de avatar
void _showAvatarOptions(BuildContext context, String userId) {
  final userProvider = Provider.of<UserProvider>(context, listen: false);
  
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galería'),
              onTap: () async {
                Navigator.pop(context);
                await userProvider.selectAndProcessAvatar(
                  ImageSource.gallery, 
                  userId
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Cámara'),
              onTap: () async {
                Navigator.pop(context);
                await userProvider.selectAndProcessAvatar(
                  ImageSource.camera, 
                  userId
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Eliminar foto de perfil'),
              onTap: () async {
                Navigator.pop(context);
                await userProvider.removeAvatar(userId);
              },
            ),
          ],
        ),
      );
    },
  );
}
  // Diálogo para reportar usuario
  void _showReportUserDialog(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reportar usuario'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Si este usuario está violando las normas de la comunidad, puedes reportarlo para que un moderador lo revise.',
              ),
              const SizedBox(height: 16),
              const Text(
                'Razón del reporte:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const TextField(
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Describe por qué estás reportando a este usuario',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                // Mostrar mensaje de confirmación
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Usuario reportado correctamente'),
                  ),
                );
                // TODO: Implementar lógica de reporte de usuario
              },
              child: const Text('Reportar'),
            ),
          ],
        );
      },
    );
  }
}

// Placeholder para la pantalla de edición de perfil
class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Perfil')),
      body: const Center(child: Text('Pantalla de edición de perfil')),
    );
  }
}

// Placeholder para la pantalla de chat
class ChatScreen extends StatelessWidget {
  final String otherUserId;
  final String otherUsername;
  
  const ChatScreen({
    super.key,
    required this.otherUserId,
    required this.otherUsername,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(otherUsername)),
      body: const Center(child: Text('Pantalla de chat')),
    );
  }
}