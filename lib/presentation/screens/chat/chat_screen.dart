import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:buapnet/data/models/chat_model.dart';
import 'package:buapnet/presentation/providers/auth_provider.dart';
import 'package:buapnet/presentation/providers/chat_provider.dart';
import 'package:buapnet/presentation/screens/profile/profile_screen.dart';
import 'package:buapnet/utils/image_utility.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String otherUsername;
  
  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherUserId,
    required this.otherUsername,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  bool _showEmojiPicker = false;
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    
    // Iniciar carga de mensajes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Inicializar mensajes
      chatProvider.initChatMessages(widget.chatId);
      
      // Marcar mensajes como leídos
      if (authProvider.user != null) {
        chatProvider.markMessagesAsRead(
          chatId: widget.chatId,
          userId: authProvider.user!.uid,
        );
      }
    });
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  // Seleccionar imagen de la galería
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }
  
  // Tomar foto con la cámara
  Future<void> _takePicture() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }
  
  // Cancelar envío de imagen
  void _cancelImage() {
    setState(() {
      _selectedImage = null;
    });
  }
  
  // Enviar mensaje
  Future<void> _sendMessage() async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;
    
    if (userId == null) return;
    
    if (_selectedImage != null) {
      // Enviar mensaje con imagen
      await chatProvider.sendMediaMessage(
        chatId: widget.chatId,
        senderId: userId,
        content: _messageController.text.trim(),
        mediaFile: _selectedImage!,
      );
      
      setState(() {
        _selectedImage = null;
      });
    } else if (_messageController.text.trim().isNotEmpty) {
      // Enviar mensaje de texto
      await chatProvider.sendTextMessage(
        chatId: widget.chatId,
        senderId: userId,
        content: _messageController.text.trim(),
      );
    }
    
    _messageController.clear();
    
    // Desplazarse hacia abajo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  
  // Agrupar mensajes por fecha
  Map<String, List<MessageModel>> _groupMessagesByDate(List<MessageModel> messages) {
    final Map<String, List<MessageModel>> groupedMessages = {};
    
    for (final message in messages) {
      final dateString = DateFormat('yyyy-MM-dd').format(message.timestamp);
      
      if (!groupedMessages.containsKey(dateString)) {
        groupedMessages[dateString] = [];
      }
      
      groupedMessages[dateString]!.add(message);
    }
    
    return groupedMessages;
  }
  
  // Formatear fecha de los mensajes
  String _formatMessageDate(String dateString) {
    final date = DateFormat('yyyy-MM-dd').parse(dateString);
    final now = DateTime.now();
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    
    if (DateFormat('yyyy-MM-dd').format(now) == dateString) {
      return 'Hoy';
    } else if (DateFormat('yyyy-MM-dd').format(yesterday) == dateString) {
      return 'Ayer';
    } else {
      return DateFormat.yMMMd('es').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.user?.uid ?? '';
    final theme = Theme.of(context);
    
    // Agrupar mensajes por fecha
    final groupedMessages = _groupMessagesByDate(chatProvider.messages);
    
    // Ordenar las fechas (más recientes primero)
    final sortedDates = groupedMessages.keys.toList()
      ..sort((a, b) => b.compareTo(a));
    
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () {
            // Navegar al perfil del otro usuario
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileScreen(userId: widget.otherUserId),
              ),
            );
          },
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                child: Text(
                  widget.otherUsername.isNotEmpty
                      ? widget.otherUsername[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(widget.otherUsername),
            ],
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // Mostrar menú de opciones
              _showChatOptionsMenu(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Indicador de carga
          if (chatProvider.isLoading && chatProvider.messages.isEmpty)
            const LinearProgressIndicator(),
          
          // Mensajes
          Expanded(
            child: chatProvider.messages.isEmpty
                ? Center(
                    child: Text(
                      'No hay mensajes aún. ¡Inicia la conversación!',
                      style: theme.textTheme.bodyLarge,
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: sortedDates.length,
                    itemBuilder: (context, index) {
                      final date = sortedDates[index];
                      final messagesForDate = groupedMessages[date]!;
                      
                      // Ordenar mensajes de más reciente a más antiguo
                      messagesForDate.sort((a, b) => b.timestamp.compareTo(a.timestamp));
                      
                      return Column(
                        children: [
                          // Separador de fecha
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 16),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Text(
                              _formatMessageDate(date),
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                          
                          // Mensajes de este día
                          ...messagesForDate.map((message) {
                            final bool isMe = message.senderId == currentUserId;
                            
                            return _buildMessageItem(message, isMe);
                          }).toList(),
                        ],
                      );
                    },
                  ),
          ),
          
          // Área de imagen seleccionada
          if (_selectedImage != null)
            Container(
              padding: const EdgeInsets.all(8),
              color: theme.colorScheme.surface,
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      _selectedImage!,
                      height: 60,
                      width: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Imagen seleccionada',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _cancelImage,
                  ),
                ],
              ),
            ),
          
          // Área de entrada de mensaje
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, -1),
                  blurRadius: 3,
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Botones de multimedia
                  IconButton(
                    icon: const Icon(Icons.attach_file),
                    onPressed: () {
                      _showAttachmentOptions(context);
                    },
                  ),
                  
                  // Campo de texto
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Escribe un mensaje...',
                        border: InputBorder.none,
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                  
                  // Botón de enviar
                  IconButton(
                    icon: chatProvider.isSendingMessage
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    onPressed: chatProvider.isSendingMessage ? null : _sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Construir un item de mensaje
  Widget _buildMessageItem(MessageModel message, bool isMe) {
    final theme = Theme.of(context);
    final maxWidth = MediaQuery.of(context).size.width * 0.7;
    
    // Formatear la hora del mensaje
    final timeString = DateFormat.jm().format(message.timestamp);
    
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(maxWidth: maxWidth),
        decoration: BoxDecoration(
          color: isMe 
              ? theme.colorScheme.primary
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen (si existe)
            if (message.mediaBase64 != null && message.mediaBase64!.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                child: CachedNetworkImage(
                  imageUrl: message.mediaBase64!,
                  fit: BoxFit.cover,
                  width: maxWidth,
                  placeholder: (context, url) => Container(
                    height: 150,
                    color: Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 150,
                    color: Colors.grey[200],
                    child: const Icon(Icons.error),
                  ),
                ),
              ),
            ],
            
            // Contenido del mensaje
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Texto del mensaje
                  if (message.content.isNotEmpty)
                    Text(
                      message.content,
                      style: TextStyle(
                        color: isMe 
                            ? Colors.white 
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  
                  // Hora del mensaje
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            timeString,
                            style: TextStyle(
                              fontSize: 10,
                              color: isMe 
                                  ? Colors.white.withOpacity(0.7) 
                                  : theme.colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                          const SizedBox(width: 4),
                          if (isMe)
                            Icon(
                              message.isRead ? Icons.done_all : Icons.done,
                              size: 12,
                              color: Colors.white.withOpacity(0.7),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Mostrar opciones de adjuntos
  void _showAttachmentOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galería'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Cámara'),
                onTap: () {
                  Navigator.pop(context);
                  _takePicture();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBase64Image(String base64String, {double? maxWidth, double? height}) {
  final ImageProvider? imageProvider = ImageUtility.base64ToImage(base64String);
  
  return SizedBox(
    width: maxWidth,
    height: height,
    child: imageProvider != null
        ? Image(
            image: imageProvider,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('Error loading message image: $error');
              return Container(
                color: Colors.grey[200],
                child: const Center(
                  child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
                ),
              );
            },
          )
        : Container(
            color: Colors.grey[200],
            child: const Center(
              child: Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
            ),
          ),
  );
}
  
  // Mostrar opciones de chat
  void _showChatOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Ver perfil'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileScreen(userId: widget.otherUserId),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  'Borrar conversación',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteChat(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
  
  // Confirmar eliminación de chat
  void _confirmDeleteChat(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar conversación'),
          content: const Text(
            '¿Estás seguro de que deseas eliminar esta conversación? Esta acción no se puede deshacer.',
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
                // TODO: Implementar eliminación de chat
                Navigator.pop(context); // Cerrar diálogo
                Navigator.pop(context); // Volver a la lista de chats
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }
}