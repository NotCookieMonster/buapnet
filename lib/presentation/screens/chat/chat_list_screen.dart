import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:buapnet/data/models/chat_model.dart';
import 'package:buapnet/presentation/providers/auth_provider.dart';
import 'package:buapnet/presentation/providers/chat_provider.dart';
import 'package:buapnet/presentation/providers/user_provider.dart';
import 'package:buapnet/presentation/screens/chat/chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    
    // Inicializar los chats del usuario
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      
      if (authProvider.user != null) {
        chatProvider.initUserChats(authProvider.user!.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    
    // Ordenar chats por último mensaje (más reciente primero)
    final chats = List<ChatModel>.from(chatProvider.chats)
      ..sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
    
    if (chatProvider.isLoading && chats.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (chats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: theme.colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No tienes conversaciones aún',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Inicia un chat desde el perfil de otro usuario',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Navegar a pantalla de búsqueda para encontrar usuarios
                // o mostrar un diálogo con lista de moderadores para contactar
                _showStartChatDialog(context, authProvider.user?.uid ?? '');
              },
              icon: const Icon(Icons.add),
              label: const Text('Iniciar nueva conversación'),
            ),
          ],
        ),
      );
    }
    
    return Column(
      children: [
        // Encabezado
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Text(
                'Conversaciones',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  // Mostrar diálogo de iniciar conversación
                  _showStartChatDialog(context, authProvider.user?.uid ?? '');
                },
                tooltip: 'Nueva conversación',
              ),
            ],
          ),
        ),
        
        // Lista de chats
        Expanded(
          child: ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final currentUserId = authProvider.user?.uid ?? '';
              
              // Obtener información del otro participante
              final otherUsername = chat.getOtherParticipantUsername(currentUserId);
              final otherUserAvatar = chat.getOtherParticipantAvatar(currentUserId);
              final otherUserId = chat.getOtherParticipantId(currentUserId);
              
              // Verificar si es el remitente del último mensaje
              final isLastMessageFromMe = chat.lastMessageSenderId == currentUserId;
              
              return ListTile(
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                  backgroundImage: otherUserAvatar.isNotEmpty
                      ? CachedNetworkImageProvider(otherUserAvatar)
                      : null,
                  child: otherUserAvatar.isEmpty
                      ? Text(
                          otherUsername.isNotEmpty
                              ? otherUsername[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        otherUsername,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (chat.isModeratorChat) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.verified,
                        size: 16,
                        color: theme.colorScheme.secondary,
                      ),
                    ],
                  ],
                ),
                subtitle: Row(
                  children: [
                    if (isLastMessageFromMe)
                      Text(
                        'Tú: ',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    Expanded(
                      child: Text(
                        chat.lastMessageText.isEmpty
                            ? 'Inicia la conversación'
                            : chat.lastMessageText,
                        style: theme.textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      timeago.format(chat.lastMessageTime, locale: 'es'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Aquí podríamos agregar un indicador de mensajes no leídos
                  ],
                ),
                onTap: () {
                  // Navegar a la pantalla de chat
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        chatId: chat.id,
                        otherUserId: otherUserId,
                        otherUsername: otherUsername,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
  
  // Mostrar diálogo para iniciar una nueva conversación
  void _showStartChatDialog(BuildContext context, String currentUserId) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    // Obtener lista de moderadores
    final moderators = await userProvider.getModerators();
    
    if (!context.mounted) return;
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nueva conversación'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Contactar a un moderador:'),
                const SizedBox(height: 8),
                if (moderators.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('No hay moderadores disponibles'),
                  )
                else
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: moderators.length,
                      itemBuilder: (context, index) {
                        final moderator = moderators[index];
                        final theme = Theme.of(context);
                        
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.secondary.withOpacity(0.2),
                            backgroundImage: moderator.avatarBase64.isNotEmpty
                                ? CachedNetworkImageProvider(moderator.avatarBase64)
                                : null,
                            child: moderator.avatarBase64.isEmpty
                                ? Text(
                                    moderator.username.isNotEmpty
                                        ? moderator.username[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      color: theme.colorScheme.secondary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                          title: Text(moderator.username),
                          subtitle: const Text('Moderador'),
                          onTap: () {
                            Navigator.pop(context);
                            _startChatWithUser(
                              context,
                              currentUserId,
                              moderator.uid,
                              moderator.username,
                              isModeratorChat: true,
                            );
                          },
                        );
                      },
                    ),
                  ),
                
                const SizedBox(height: 16),
                const Text('O buscar a otro usuario:'),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    // Navegar a la pantalla de búsqueda
                    Navigator.pushNamed(context, '/search');
                  },
                  icon: const Icon(Icons.search),
                  label: const Text('Buscar usuarios'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 40),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }
  
  // Iniciar un chat con un usuario específico
  void _startChatWithUser(
    BuildContext context,
    String currentUserId,
    String otherUserId,
    String otherUsername, {
    bool isModeratorChat = false,
  }) async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    
    try {
      final chat = await chatProvider.getOrCreateChat(
        currentUserId: currentUserId,
        otherUserId: otherUserId,
        isModeratorChat: isModeratorChat,
      );
      
      if (chat != null && context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              chatId: chat.id,
              otherUserId: otherUserId,
              otherUsername: otherUsername,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
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