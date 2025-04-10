import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:buapnet/data/models/post_model.dart';
import 'package:buapnet/presentation/providers/auth_provider.dart';
import 'package:buapnet/presentation/providers/post_provider.dart';
import 'package:buapnet/presentation/providers/chat_provider.dart';
import 'package:buapnet/presentation/widgets/post_card.dart';
import 'package:buapnet/presentation/screens/home/post_detail_screen.dart';

class ModeratorDashboard extends StatefulWidget {
  const ModeratorDashboard({super.key});

  @override
  State<ModeratorDashboard> createState() => _ModeratorDashboardState();
}

class _ModeratorDashboardState extends State<ModeratorDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);

    // Inicializar datos
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final postProvider = Provider.of<PostProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);

      if (authProvider.user != null) {
        // Inicializar publicaciones pendientes de aprobación
        postProvider.initPendingPosts();
        
        // Inicializar publicaciones reportadas
        postProvider.initReportedPosts();
        
        // Inicializar chats de moderador
        chatProvider.initModeratorChats(authProvider.user!.uid);
      }
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final postProvider = Provider.of<PostProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.user?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Moderación'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pendientes'),
            Tab(text: 'Reportados'),
          ],
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onBackground.withOpacity(0.7),
          indicatorColor: theme.colorScheme.primary,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Pestaña de publicaciones pendientes
          _buildPendingPostsTab(postProvider, currentUserId),
          
          // Pestaña de publicaciones reportadas
          _buildReportedPostsTab(postProvider, currentUserId),
        ],
      ),
    );
  }
  
  // Construir la pestaña de publicaciones pendientes
  Widget _buildPendingPostsTab(PostProvider postProvider, String currentUserId) {
    final theme = Theme.of(context);
    
    if (postProvider.isLoading && postProvider.pendingPosts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (postProvider.pendingPosts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: theme.colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No hay publicaciones pendientes',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Todas las publicaciones han sido revisadas',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: () async {
        postProvider.initPendingPosts();
      },
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: postProvider.pendingPosts.length,
        itemBuilder: (context, index) {
          final post = postProvider.pendingPosts[index];
          
          return _buildModeratorPostCard(
            post: post,
            currentUserId: currentUserId,
            isPending: true,
          );
        },
      ),
    );
  }
  
  // Construir la pestaña de publicaciones reportadas
  Widget _buildReportedPostsTab(PostProvider postProvider, String currentUserId) {
    final theme = Theme.of(context);
    
    if (postProvider.isLoading && postProvider.reportedPosts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (postProvider.reportedPosts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: theme.colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No hay publicaciones reportadas',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'No se han reportado publicaciones',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: () async {
        postProvider.initReportedPosts();
      },
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: postProvider.reportedPosts.length,
        itemBuilder: (context, index) {
          final post = postProvider.reportedPosts[index];
          
          return _buildModeratorPostCard(
            post: post,
            currentUserId: currentUserId,
            isPending: false,
          );
        },
      ),
    );
  }
  
  // Construir tarjeta de publicación para moderadores
  Widget _buildModeratorPostCard({
    required PostModel post,
    required String currentUserId,
    required bool isPending,
  }) {
    final theme = Theme.of(context);
    final postProvider = Provider.of<PostProvider>(context, listen: false);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado de moderación
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: isPending
                ? theme.colorScheme.primary.withOpacity(0.1)
                : theme.colorScheme.error.withOpacity(0.1),
            child: Row(
              children: [
                Icon(
                  isPending ? Icons.pending : Icons.flag,
                  size: 18,
                  color: isPending
                      ? theme.colorScheme.primary
                      : theme.colorScheme.error,
                ),
                const SizedBox(width: 8),
                Text(
                  isPending
                      ? 'Pendiente de aprobación'
                      : 'Reportado ${post.reportsCount} ${post.reportsCount == 1 ? 'vez' : 'veces'}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isPending
                        ? theme.colorScheme.primary
                        : theme.colorScheme.error,
                  ),
                ),
                const Spacer(),
                if (!isPending)
                  Text(
                    post.isHidden ? 'Oculto' : 'Visible',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: post.isHidden
                          ? theme.colorScheme.error
                          : theme.colorScheme.primary,
                    ),
                  ),
              ],
            ),
          ),
          
          // Contenido de la publicación
          PostCard(
            post: post,
            currentUserId: currentUserId,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PostDetailScreen(postId: post.id),
                ),
              );
            },
            showFullContent: true,
          ),
          
          // Botones de acción para moderadores
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (isPending) ...[
                  // Aprobar publicación
                  OutlinedButton.icon(
                    onPressed: () {
                      _confirmModeratorAction(
                        context: context,
                        title: 'Aprobar publicación',
                        message: '¿Estás seguro que deseas aprobar esta publicación?',
                        confirmLabel: 'Aprobar',
                        isDestructive: false,
                        onConfirm: () async {
                          final success = await postProvider.approvePost(post.id);
                          if (success && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Publicación aprobada correctamente'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                      );
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Aprobar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                    ),
                  ),
                  
                  // Rechazar publicación
                  OutlinedButton.icon(
                    onPressed: () {
                      _confirmModeratorAction(
                        context: context,
                        title: 'Rechazar publicación',
                        message: '¿Estás seguro que deseas rechazar esta publicación? Será oculta para todos los usuarios.',
                        confirmLabel: 'Rechazar',
                        isDestructive: true,
                        onConfirm: () async {
                          final success = await postProvider.hidePost(post.id);
                          if (success && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Publicación rechazada correctamente'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                      );
                    },
                    icon: const Icon(Icons.close),
                    label: const Text('Rechazar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ] else ...[
                  // Ocultar/Mostrar publicación
                  OutlinedButton.icon(
                    onPressed: () {
                      final isHidden = post.isHidden;
                      _confirmModeratorAction(
                        context: context,
                        title: isHidden ? 'Mostrar publicación' : 'Ocultar publicación',
                        message: isHidden
                            ? '¿Estás seguro que deseas hacer visible esta publicación?'
                            : '¿Estás seguro que deseas ocultar esta publicación? No será visible para ningún usuario.',
                        confirmLabel: isHidden ? 'Mostrar' : 'Ocultar',
                        isDestructive: !isHidden,
                        onConfirm: () async {
                          final success = isHidden
                              ? await postProvider.unhidePost(post.id)
                              : await postProvider.hidePost(post.id);
                          if (success && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isHidden
                                    ? 'Publicación visible correctamente'
                                    : 'Publicación ocultada correctamente'),
                                backgroundColor: isHidden ? Colors.green : Colors.red,
                              ),
                            );
                          }
                        },
                      );
                    },
                    icon: Icon(post.isHidden ? Icons.visibility : Icons.visibility_off),
                    label: Text(post.isHidden ? 'Mostrar' : 'Ocultar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: post.isHidden ? Colors.green : Colors.red,
                    ),
                  ),
                  
                  // Contactar al autor
                  OutlinedButton.icon(
                    onPressed: () {
                      _contactAuthor(context, post.authorId, post.authorUsername);
                    },
                    icon: const Icon(Icons.chat),
                    label: const Text('Contactar autor'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Mostrar diálogo de confirmación para acciones de moderador
  void _confirmModeratorAction({
    required BuildContext context,
    required String title,
    required String message,
    required String confirmLabel,
    required bool isDestructive,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
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
                onConfirm();
              },
              style: FilledButton.styleFrom(
                backgroundColor: isDestructive ? Colors.red : Colors.green,
              ),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
  }
  
  // Contactar al autor de una publicación
  void _contactAuthor(BuildContext context, String authorId, String authorUsername) async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.user?.uid ?? '';
    
    if (currentUserId.isEmpty) return;
    
    try {
      final chat = await chatProvider.getOrCreateChat(
        currentUserId: currentUserId,
        otherUserId: authorId,
        isModeratorChat: true,
      );
      
      if (chat != null && mounted) {
        Navigator.pushNamed(
          context,
          '/chat',
          arguments: {
            'chatId': chat.id,
            'otherUserId': authorId,
            'otherUsername': authorUsername,
          },
        );
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
}