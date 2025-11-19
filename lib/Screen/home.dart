import 'package:diurecycle/Screen/add_product_page.dart';
import 'package:diurecycle/Screen/chats_list_screen.dart';
import 'package:diurecycle/Screen/product_details_screen.dart';
import 'package:diurecycle/Screen/profile_page.dart';
import 'package:diurecycle/Screen/settings_screen.dart';
import 'package:diurecycle/services/auth_service.dart';
import 'package:diurecycle/services/chat_service.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;
  String _selectedCategory = 'all'; // Default to 'all' category
  String _searchQuery = '';
  int _selectedBottomNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildCategories(),
          Expanded(
            child: _buildProductGrid(),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

 _buildAppBar() {
  
  return AppBar(
    title: Text(
      'DIU Recycle',
      style: TextStyle(
        color: Colors.green.shade800,
        fontWeight: FontWeight.bold,
        fontSize: 24,
      ),
    ),
    backgroundColor: Colors.white,
    elevation: 0,
  );
}

  Widget _buildBottomNavigationBar() {
    return StreamBuilder<int>(
      stream: _getTotalUnreadMessagesCount(),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;

        return BottomNavigationBar(
          currentIndex: _selectedBottomNavIndex,
          onTap: _onNavItemTapped,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.green.shade700,
          unselectedItemColor: Colors.grey.shade600,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.message_outlined),
                  if (unreadCount > 0)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              activeIcon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.message),
                  if (unreadCount > 0)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              label: 'Chats',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline),
              activeIcon: Icon(Icons.add_circle),
              label: 'Add',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        );
      },
    );
  }

  void _onNavItemTapped(int index) {
    if (index == 0) {
      setState(() {
        _selectedBottomNavIndex = 0;
      });
      return;
    }

    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AddProductScreen()),
      ).then((_) {
        if (!mounted) return;
        setState(() {
          _selectedBottomNavIndex = 0;
        });
      });
      return;
    }

    setState(() {
      _selectedBottomNavIndex = index;
    });

    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ChatsListScreen()),
      ).then((_) {
        if (!mounted) return;
        setState(() {
          _selectedBottomNavIndex = 0;
        });
      });
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ProfilePage()),
      ).then((_) {
        if (!mounted) return;
        setState(() {
          _selectedBottomNavIndex = 0;
        });
      });
    } else if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SettingsScreen()),
      ).then((_) {
        if (!mounted) return;
        setState(() {
          _selectedBottomNavIndex = 0;
        });
      });
    }
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search items...',
          prefixIcon: Icon(Icons.search, color: Colors.green.shade600),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.green.shade400, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildCategories() {
    // Add "All" category to the beginning of the list
    final allCategories = [
      Category(id: 'all', name: 'All', icon: Icons.category),
      ...Category.defaultCategories,
    ];

    return SizedBox(
      height: 130,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 16.0, bottom: 12.0),
            child: Text(
              'Categories',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade800,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: allCategories.length,
              itemBuilder: (context, index) {
                final category = allCategories[index];
                final isSelected = _selectedCategory == category.id;
                
                return TweenAnimationBuilder(
                  duration: Duration(milliseconds: 200),
                  tween: Tween<double>(begin: 0, end: isSelected ? 1 : 0),
                  builder: (context, double value, child) {
                    return Container(
                      width: 100,
                      margin: EdgeInsets.only(right: 12.0),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategory = category.id;
                          });
                          _animationController.forward(from: 0);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Color.lerp(
                              Colors.white,
                              Colors.green.shade50,
                              value,
                            ),
                            borderRadius: BorderRadius.circular(16.0),
                            border: Border.all(
                              color: Color.lerp(
                                Colors.grey.shade300,
                                Colors.green.shade400,
                                value,
                              )!,
                              width: 1.5 + (0.5 * value),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Color.lerp(
                                    Colors.grey.shade50,
                                    Colors.green.shade100,
                                    value,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  category.icon,
                                  color: Color.lerp(
                                    Colors.green.shade700,
                                    Colors.green.shade700,
                                    value,
                                  ),
                                  size: 28,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                category.name,
                                style: TextStyle(
                                  color: Color.lerp(
                                    Colors.grey.shade700,
                                    Colors.green.shade800,
                                    value,
                                  ),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: _buildProductsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red.shade300,
                ),
                SizedBox(height: 16),
                Text(
                  'Something went wrong',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Please try again later',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        final products = snapshot.data!.docs
            .map((doc) => Product.fromFirestore(doc))
            .where((product) {
          // Always search across all products, regardless of category selection
          final matchesSearch = _searchQuery.isEmpty || 
              product.title.toLowerCase().contains(_searchQuery.toLowerCase());
              
          // Only filter by category if not 'all'
          final matchesCategory = _selectedCategory == 'all' || 
              product.category == _selectedCategory;
              
          return matchesSearch && matchesCategory;
        }).toList();

        if (products.isEmpty) {
          return _buildEmptyState();
        }

        return GridView.builder(
          padding: EdgeInsets.all(16.0),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return _buildProductCard(product);
          },
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade400),
                  strokeWidth: 3,
                ),
              ),
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Loading items...',
            style: TextStyle(
              color: Colors.green.shade800,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _searchQuery.isEmpty ? Icons.category_outlined : Icons.search_off,
              size: 60,
              color: Colors.green.shade300,
            ),
          ),
          SizedBox(height: 24),
          Text(
            _searchQuery.isEmpty
                ? _selectedCategory == 'all'
                    ? 'No items available'
                    : 'No items in this category'
                : 'No items match your search',
            style: TextStyle(
              color: Colors.green.shade800,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'Try selecting a different category'
                : 'Try adjusting your search terms',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 24),
          TextButton(
            onPressed: () {
              setState(() {
                _searchQuery = '';
                _searchController.clear();
                _selectedCategory = 'all';
              });
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              backgroundColor: Colors.green.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Clear Filters',
              style: TextStyle(
                color: Colors.green.shade700,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _buildProductsStream() {
    return FirebaseFirestore.instance
        .collection('products')
        .where('isAvailable', isEqualTo: true)
        .where('expiresAt', isGreaterThan: Timestamp.now())
        .orderBy('expiresAt', descending: true)
        .limit(50) 
        .snapshots();
  }

  Widget _buildProductCard(Product product) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailsScreen(product: product),
          ),
        );
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12.0)),
              child: SizedBox(
                height: 120,
                width: double.infinity,
                child: product.imageUrls.isNotEmpty
                    ? Image.network(
                        product.imageUrls[0],
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                              color: Colors.green.shade400,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          if (kDebugMode) {
                            print('Error loading image: $error');
                          }
                          return Container(
                            color: Colors.grey.shade200,
                            child: Center(
                              child: Icon(
                                Icons.broken_image_outlined,
                                size: 50,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey.shade200,
                        child: Center(
                          child: Icon(
                            Icons.image_not_supported,
                            size: 50,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    '৳${product.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Expires in: ${_getTimeUntilExpiry(product.expiresAt)}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTimeUntilExpiry(DateTime expiryDate) {
    final now = DateTime.now();
    final difference = expiryDate.difference(now);

    if (difference.inDays > 0) {
      return '${difference.inDays} days';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours';
    } else {
      return '${difference.inMinutes} minutes';
    }
  }
  
  // Add this method to your class
Stream<int> _getTotalUnreadMessagesCount() {
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  final String currentUserId = _authService.getCurrentUserId() ?? '';
    
  return _chatService.getUserChats().map((chats) {
    int totalUnread = 0;
        
    for (final chat in chats) {
      // Count unread messages for current user
      totalUnread += chat.getUnreadCountFor(currentUserId);
    }
        
    return totalUnread;
  });
}
}