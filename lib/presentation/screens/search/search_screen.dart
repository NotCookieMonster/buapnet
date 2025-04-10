import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:buapnet/data/models/post_model.dart';
import 'package:buapnet/data/models/user_model.dart';
import 'package:buapnet/presentation/providers/auth_provider.dart';
import 'package:buapnet/presentation/providers/post_provider.dart';
import 'package:buapnet/presentation/providers/user_provider.dart';
import 'package:buapnet/presentation/widgets/post_card.dart';
import 'package:buapnet/presentation/screens/home/post_detail_screen.dart';
import 'package:buapnet/presentation/screens/profile/profile_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearching = false;
  String _currentQuery = '';
  TabController? _tabController;
  int _currentTabIndex = 0;
  List<UserModel> _userResults = [];
  bool _isLoadingUsers = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController!.addListener(_handleTabChange);
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _tabController?.removeListener(_handleTabChange);
    _tabController?.dispose();
    super.dispose();
  }
  
  void _handleTabChange() {
    if (_tabController!.indexIsChanging) {
      setState(() {
        _currentTabIndex = _tabController!.index;
      });
      
      // Si cambiamos a la pestaña de usuarios y hay una consulta, buscar usuarios
      if (_currentTabIndex == 1 && _currentQuery.isNotEmpty) {
        _searchUsers(_currentQuery);
      }
    }
  }
  
  // Iniciar búsqueda
  void _performSearch(String query) {
    setState(() {
      _isSearching = true;
      _currentQuery = query;
    });
    
    if (_currentTabIndex == 0) {
      // Buscar publicaciones
      Provider.of<PostProvider>(context, listen: false).searchPosts(query);
    } else {
      // Buscar usuarios
      _searchUsers(query);
    }
  }
  
  // Buscar usuarios
  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _userResults = [];
        _isLoadingUsers = false;
      });
      return;
    }
    
    setState(() {
      _isLoadingUsers = true;
    });
    
    try {
      final users = await Provider.of<UserProvider>(context, listen: false)
          .searchUsers(query);
      
      setState(() {
        _userResults = users;
        _isLoadingUsers = false;
      });
    } catch (e) {
      setState(() {
        _userResults = [];
        _isLoadingUsers = false;
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
  
  // Cancelar búsqueda
  void _cancelSearch() {
    setState(() {
      _isSearching = false;
      _currentQuery = '';
      _searchController.clear();
      _userResults = [];
    });
    
    Provider.of<PostProvider>(context, listen: false).cancelSearch();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final postProvider = Provider.of<PostProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.user?.uid ?? '';
    
    return Column(
      children: [
        // Barra de búsqueda
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            decoration: InputDecoration(
              hintText: 'Buscar publicaciones o usuarios...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _isSearching
                  ? IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: _cancelSearch,
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
                borderSide: BorderSide.none,
              ),
              filled: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
            onSubmitted: (query) {
              if (query.isNotEmpty) {
                _performSearch(query);
              }
            },
          ),
        ),
        
        // Tabs para elegir entre publicaciones y usuarios
        if (_isSearching)
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Publicaciones'),
              Tab(text: 'Usuarios'),
            ],
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onBackground.withOpacity(0.7),
            indicatorColor: theme.colorScheme.primary,
          ),
        
        // Resultados de búsqueda
        if (_isSearching)
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Pestaña de publicaciones
                _buildPostsResultsTab(postProvider, currentUserId),
                
                // Pestaña de usuarios
                _buildUsersResultsTab(),
              ],
            ),
          )
        else
          _buildSearchSuggestions(),
      ],
    );
  }
  
  // Construir sugerencias de búsqueda
  Widget _buildSearchSuggestions() {
    final theme = Theme.of(context);
    
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sugerencias de búsqueda',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Lista de sugerencias
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildSearchChip('Exámenes'),
                _buildSearchChip('Asesorías'),
                _buildSearchChip('Eventos'),
                _buildSearchChip('Becas'),
                _buildSearchChip('Computación'),
                _buildSearchChip('Matemáticas'),
                _buildSearchChip('Ingeniería'),
                _buildSearchChip('Medicina'),
                _buildSearchChip('Derecho'),
              ],
            ),
            
            const SizedBox(height: 24),
            Text(
              'Tags populares',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Lista de tags populares
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildSearchChip('#ayuda', isTag: true),
                _buildSearchChip('#consejos', isTag: true),
                _buildSearchChip('#pregunta', isTag: true),
                _buildSearchChip('#BUAP', isTag: true),
                _buildSearchChip('#recursos', isTag: true),
                _buildSearchChip('#tesis', isTag: true),
                _buildSearchChip('#servicio', isTag: true),
                _buildSearchChip('#biblioteca', isTag: true),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // Construir un chip de sugerencia de búsqueda
  Widget _buildSearchChip(String label, {bool isTag = false}) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        _searchController.text = isTag ? label.substring(1) : label;
        _performSearch(_searchController.text);
        _searchFocusNode.unfocus();
      },
    );
  }
  
  // Construir la pestaña de resultados de publicaciones
  Widget _buildPostsResultsTab(PostProvider postProvider, String currentUserId) {
    final theme = Theme.of(context);
    
    if (postProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_currentQuery.isEmpty) {
      return Center(
        child: Text(
          'Ingresa un término de búsqueda',
          style: theme.textTheme.titleMedium,
        ),
      );
    }
    
    if (postProvider.searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: theme.colorScheme.onBackground.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No se encontraron resultados',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Intenta con otro término de búsqueda',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: postProvider.searchResults.length,
      itemBuilder: (context, index) {
        final post = postProvider.searchResults[index];
        
        return PostCard(
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
        );
      },
    );
  }
  
  // Construir la pestaña de resultados de usuarios
  Widget _buildUsersResultsTab() {
    final theme = Theme.of(context);
    
    if (_isLoadingUsers) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_currentQuery.isEmpty) {
      return Center(
        child: Text(
          'Ingresa un nombre de usuario para buscar',
          style: theme.textTheme.titleMedium,
        ),
      );
    }
    
    if (_userResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_search,
              size: 64,
              color: theme.colorScheme.onBackground.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No se encontraron usuarios',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Intenta con otro nombre de usuario',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: _userResults.length,
      itemBuilder: (context, index) {
        final user = _userResults[index];
        
        return ListTile(
          leading: CircleAvatar(
            radius: 24,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
            backgroundImage: user.avatarBase64.isNotEmpty
                ? CachedNetworkImageProvider(user.avatarBase64)
                : null,
            child: user.avatarBase64.isEmpty
                ? Text(
                    user.username.isNotEmpty
                        ? user.username[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          title: Text(
            user.username,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: user.faculty.isNotEmpty ? Text(user.faculty) : null,
          trailing: user.isModerator
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Moderador',
                    style: TextStyle(
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                )
              : null,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileScreen(userId: user.uid),
              ),
            );
          },
        );
      },
    );
  }
}