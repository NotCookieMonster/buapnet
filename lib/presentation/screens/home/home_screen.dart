import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:buapnet/presentation/providers/auth_provider.dart';
import 'package:buapnet/presentation/providers/post_provider.dart';
import 'package:buapnet/presentation/providers/theme_provider.dart';
import 'package:buapnet/data/models/post_model.dart';
import 'package:buapnet/presentation/screens/home/create_post_screen.dart';
import 'package:buapnet/presentation/screens/home/post_detail_screen.dart';
import 'package:buapnet/presentation/screens/profile/profile_screen.dart';
import 'package:buapnet/presentation/screens/search/search_screen.dart';
import 'package:buapnet/presentation/screens/chat/chat_list_screen.dart';
import 'package:buapnet/presentation/screens/moderator/moderator_dashboard.dart';
import 'package:buapnet/presentation/widgets/post_card.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final List<String> _titles = ['Feed', 'Buscar', 'Chats', 'Perfil'];
  
  @override
  void initState() {
    super.initState();
    // Iniciar la carga del feed de publicaciones
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PostProvider>(context, listen: false).initPostsFeed();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);
    final user = authProvider.user;
    
    // Lista de iconos para la barra de navegación
    final List<IconData> navIcons = [
      Icons.home,
      Icons.search,
      Icons.chat,
      Icons.person,
    ];
    
    // Lista de widgets para cada tab
    final List<Widget> _screens = [
      _buildFeedTab(),
      const SearchScreen(),
      const ChatListScreen(),
      ProfileScreen(userId: user?.uid ?? ''),
    ];
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        centerTitle: true,
        actions: [
          // Mostrar botón de dashboard para moderadores
          if (authProvider.isModerator && _currentIndex == 0)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              onPressed: () {
                Navigator.push(
                  context, 
                  MaterialPageRoute(
                    builder: (context) => const ModeratorDashboard(),
                  ),
                );
              },
              tooltip: 'Panel de moderación',
            ),
          // Botón de cambio de tema
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: () {
              themeProvider.toggleTheme();
            },
            tooltip: themeProvider.isDarkMode ? 'Modo claro' : 'Modo oscuro',
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: List.generate(
          _titles.length,
          (index) => NavigationDestination(
            icon: Icon(navIcons[index]),
            label: _titles[index],
          ),
        ),
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreatePostScreen(),
                  ),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
  
  Widget _buildFeedTab() {
    final postProvider = Provider.of<PostProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    
    if (postProvider.isLoading && postProvider.posts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (postProvider.error != null && postProvider.posts.isEmpty) {
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
              'Error al cargar publicaciones',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              postProvider.error ?? 'Ocurrió un error desconocido',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                postProvider.initPostsFeed();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }
    
    if (postProvider.posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.post_add,
              size: 64,
              color: theme.colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No hay publicaciones',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '¡Sé el primero en compartir algo con la comunidad!',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreatePostScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Crear publicación'),
            ),
          ],
        ),
      );
    }
    
    // Mostrar lista de publicaciones
    return RefreshIndicator(
      onRefresh: () async {
        postProvider.initPostsFeed();
      },
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: postProvider.posts.length,
        itemBuilder: (context, index) {
          final post = postProvider.posts[index];
          return PostCard(
            post: post,
            currentUserId: authProvider.user?.uid ?? '',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PostDetailScreen(postId: post.id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// Placeholder para ModeratorDashboard - Se implementará después
class ModeratorDashboard extends StatelessWidget {
  const ModeratorDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Panel de Moderación')),
      body: const Center(child: Text('Panel de moderación')),
    );
  }
}

// Placeholder para ChatListScreen - Se implementará después
class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Lista de chats'));
  }
}

// Placeholder para SearchScreen - Se implementará después
class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Buscar'));
  }
}