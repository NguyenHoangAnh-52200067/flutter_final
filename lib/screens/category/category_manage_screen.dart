// import 'package:ecommerce_app/models/category_model.dart';
// import 'package:ecommerce_app/repository/category_repository.dart';
// import 'package:ecommerce_app/screens/category/add_category_screen.dart';
// import 'package:ecommerce_app/screens/product/product_list_screen.dart';
// import 'package:ecommerce_app/utils/image_utils.dart';
// import 'package:flutter/material.dart';

// class CategoryManagementScreen extends StatefulWidget {
//   const CategoryManagementScreen({super.key});

//   @override
//   State<CategoryManagementScreen> createState() =>
//       _CategoryManagementScreenState();
// }

// class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
//   List<CategoryModel> _parentCategories = [];
//   List<CategoryModel> _filteredCategories = [];
//   Map<String, List<CategoryModel>> _subCategories = {};

//   final TextEditingController _searchController = TextEditingController();
//   final CategoryRepository _categoryRepo = CategoryRepository();
//   Set<String> _selectedCategories = {};

//   bool isGridView = false;
//   bool _isSelecting = false;

//   @override
//   void initState() {
//     super.initState();
//     _loadCategories();
//   }

//   Future<void> _loadCategories() async {
//     final parents = await _categoryRepo.getParentCategories();
//     setState(() {
//       _parentCategories = parents;
//       _filteredCategories = parents;
//     });
//     for (var parent in parents) {
//       final children = await _categoryRepo.getSubCategories(parent.id!);
//       setState(() {
//         _subCategories[parent.id!] = children;
//       });
//     }
//   }

//   void _navigateToAddCategory() async {
//     await Navigator.push(
//       context,
//       MaterialPageRoute(builder: (context) => AddCategoryScreen()),
//     );
//     _loadCategories();
//   }

//   void _filterCategories(String query) {
//     setState(() {
//       _filteredCategories =
//           _parentCategories
//               .where(
//                 (category) =>
//                     category.name.toLowerCase().contains(query.toLowerCase()),
//               )
//               .toList();
//     });
//   }

//   void _editCategory(CategoryModel category) async {
//     final result = await Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => AddCategoryScreen(category: category),
//       ),
//     );

//     if (result == true) {
//       _loadCategories();
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[200],
//       appBar: AppBar(
//         title: Text(_isSelecting ? "Chọn danh mục" : "Quản lý danh mục"),
//         backgroundColor: const Color(0xFF7AE582),
//         centerTitle: true,
//         actions:
//             _isSelecting
//                 ? [
//                   IconButton(
//                     icon: const Icon(Icons.delete),
//                     onPressed: _confirmDeleteMultipleCategories,
//                   ),
//                   IconButton(
//                     icon: const Icon(Icons.close),
//                     onPressed: () {
//                       setState(() {
//                         _isSelecting = false;
//                         _selectedCategories.clear();
//                       });
//                     },
//                   ),
//                 ]
//                 : [
//                   IconButton(
//                     icon: const Icon(Icons.add),
//                     onPressed: _navigateToAddCategory,
//                   ),
//                 ],
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(10),
//         child: Card(
//           color: Colors.white,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(15),
//           ),
//           elevation: 3,
//           child: Padding(
//             padding: const EdgeInsets.all(12),
//             child: Column(
//               children: [
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Row(
//                       children: [
//                         Container(
//                           width: 5,
//                           height: 20,
//                           color: const Color(0xFF7AE582),
//                           margin: const EdgeInsets.only(right: 10),
//                         ),
//                         const Text(
//                           "Danh mục",
//                           style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ],
//                     ),
//                     Row(
//                       children: [
//                         IconButton(
//                           icon: Icon(
//                             Icons.list,
//                             color:
//                                 !isGridView
//                                     ? const Color(0xFF7AE582)
//                                     : Colors.grey,
//                           ),
//                           onPressed: () => setState(() => isGridView = false),
//                         ),
//                         IconButton(
//                           icon: Icon(
//                             Icons.grid_view,
//                             color:
//                                 isGridView
//                                     ? const Color(0xFF7AE582)
//                                     : Colors.grey,
//                           ),
//                           onPressed: () => setState(() => isGridView = true),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),

//                 // Search
//                 Container(
//                   margin: const EdgeInsets.symmetric(vertical: 10),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(10),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.grey.withOpacity(0.2),
//                         spreadRadius: 1,
//                         blurRadius: 5,
//                         offset: const Offset(0, 2),
//                       ),
//                     ],
//                   ),
//                   child: TextField(
//                     controller: _searchController,
//                     onChanged: _filterCategories,
//                     decoration: const InputDecoration(
//                       hintText: "Tìm kiếm danh mục...",
//                       prefixIcon: Icon(Icons.search),
//                       border: InputBorder.none,
//                       contentPadding: EdgeInsets.symmetric(
//                         vertical: 12,
//                         horizontal: 16,
//                       ),
//                     ),
//                   ),
//                 ),

//                 // Danh sách danh mục
//                 Expanded(
//                   child:
//                       _filteredCategories.isEmpty
//                           ? const Center(
//                             child: Text("Không tìm thấy danh mục nào"),
//                           )
//                           : isGridView
//                           ? _buildGridView()
//                           : _buildListView(),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   // Grid View
//   Widget _buildGridView() {
//     return GridView.builder(
//       padding: const EdgeInsets.all(5),
//       itemCount: _filteredCategories.length,
//       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//         crossAxisCount: 2,
//         childAspectRatio: 0.92,
//         crossAxisSpacing: 10,
//         mainAxisSpacing: 10,
//       ),
//       itemBuilder: (context, index) {
//         final parent = _filteredCategories[index];
//         final isSelected = _selectedCategories.contains(parent.id);
//         return GestureDetector(
//           onLongPress: () {
//             setState(() {
//               _isSelecting = true;
//               _selectedCategories.add(parent.id!);
//             });
//           },
//           onTap: () {
//             if (_isSelecting) {
//               setState(() {
//                 if (isSelected) {
//                   _selectedCategories.remove(parent.id!);
//                 } else {
//                   _selectedCategories.add(parent.id!);
//                 }
//               });
//             } else {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder:
//                       (context) => ProductListScreen(
//                         categoryId: parent.id!,
//                         categoryName: parent.name,
//                       ),
//                 ),
//               );
//             }
//           },
//           child: Card(
//             color: isSelected ? Colors.grey.withOpacity(0.2) : Colors.white,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(10),
//             ),
//             elevation: 3,
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 ClipRRect(
//                   borderRadius: BorderRadius.circular(8),
//                   child: ImageUtils.buildImage(parent.imageUrl),
//                 ),
//                 const SizedBox(height: 20),
//                 Text(
//                   parent.name,
//                   style: const TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 5),
//                 if (_isSelecting)
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Checkbox(
//                         value: isSelected,
//                         activeColor: Colors.blue,
//                         onChanged: (selected) {
//                           setState(() {
//                             if (selected == true) {
//                               _selectedCategories.add(parent.id!);
//                             } else {
//                               _selectedCategories.remove(parent.id!);
//                             }
//                           });
//                         },
//                       ),
//                       if (isSelected && _selectedCategories.length == 1)
//                         IconButton(
//                           icon: const Icon(Icons.edit, color: Colors.black),
//                           onPressed: () => _editCategory(parent),
//                         ),
//                     ],
//                   ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   // List View
//   Widget _buildListView() {
//     return ListView.builder(
//       padding: const EdgeInsets.all(5),
//       itemCount: _filteredCategories.length,
//       itemBuilder: (context, index) {
//         final parent = _filteredCategories[index];
//         final isSelected = _selectedCategories.contains(parent.id);

//         return GestureDetector(
//           onLongPress: () {
//             setState(() {
//               _isSelecting = true;
//               _selectedCategories.add(parent.id!);
//             });
//           },
//           onTap: () {
//             if (_isSelecting) {
//               setState(() {
//                 if (isSelected) {
//                   _selectedCategories.remove(parent.id!);
//                 } else {
//                   _selectedCategories.add(parent.id!);
//                 }
//               });
//             } else {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder:
//                       (context) => ProductListScreen(
//                         categoryId: parent.id!,
//                         categoryName: parent.name,
//                       ),
//                 ),
//               );
//             }
//           },
//           child: Card(
//             color: isSelected ? Colors.blue.withOpacity(0.5) : Colors.white,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(10),
//             ),
//             elevation: 2,
//             margin: const EdgeInsets.only(bottom: 10),
//             child: ListTile(
//               leading: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   if (_isSelecting)
//                     Checkbox(
//                       value: isSelected,
//                       activeColor: Colors.blue,
//                       onChanged: (selected) {
//                         setState(() {
//                           if (selected == true) {
//                             _selectedCategories.add(parent.id!);
//                           } else {
//                             _selectedCategories.remove(parent.id!);
//                           }
//                         });
//                       },
//                     ),

//                   ClipRRect(
//                     borderRadius: BorderRadius.circular(5),
//                     child: ImageUtils.buildImage(parent.imageUrl),
//                   ),
//                 ],
//               ),
//               title: Text(
//                 parent.name,
//                 style: const TextStyle(fontWeight: FontWeight.bold),
//               ),

//               trailing:
//                   isSelected && _selectedCategories.length == 1
//                       ? IconButton(
//                         icon: const Icon(Icons.edit, color: Colors.black),
//                         onPressed: () => _editCategory(parent),
//                       )
//                       : null,
//             ),
//           ),
//         );
//       },
//     );
//   }

//   void _confirmDeleteMultipleCategories() {
//     if (_selectedCategories.isEmpty) return;
//     showDialog(
//       context: context,
//       builder:
//           (context) => AlertDialog(
//             title: const Text("Xác nhận xóa"),
//             content: Text(
//               "Bạn có chắc chắn muốn xóa ${_selectedCategories.length} danh mục không?",
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text("Hủy"),
//               ),
//               TextButton(
//                 onPressed: () async {
//                   for (String id in _selectedCategories) {
//                     await _categoryRepo.deleteCategory(id);
//                   }
//                   setState(() {
//                     _isSelecting = false;
//                     _selectedCategories.clear();
//                     _loadCategories();
//                   });
//                   Navigator.pop(context);
//                 },
//                 child: const Text("Xóa", style: TextStyle(color: Colors.red)),
//               ),
//             ],
//           ),
//     );
//   }
// }
import 'package:ecommerce_app/models/category_model.dart';
import 'package:ecommerce_app/repository/category_repository.dart';
import 'package:ecommerce_app/screens/category/add_category_screen.dart';
import 'package:ecommerce_app/screens/product/product_list_screen.dart';
import 'package:ecommerce_app/utils/image_utils.dart';
import 'package:flutter/material.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen>
    with TickerProviderStateMixin {
  List<CategoryModel> _parentCategories = [];
  List<CategoryModel> _filteredCategories = [];
  Map<String, List<CategoryModel>> _subCategories = {};

  final TextEditingController _searchController = TextEditingController();
  final CategoryRepository _categoryRepo = CategoryRepository();
  Set<String> _selectedCategories = {};

  bool isGridView = false;
  bool _isSelecting = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    _slideController.forward();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
    _scaleController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _scaleController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _scaleController.forward();
      }
    });

    _loadCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final parents = await _categoryRepo.getParentCategories();
    setState(() {
      _parentCategories = parents;
      _filteredCategories = parents;
      _fadeController.forward();
      _slideController.forward();
    });
    for (var parent in parents) {
      final children = await _categoryRepo.getSubCategories(parent.id!);
      setState(() {
        _subCategories[parent.id!] = children;
      });
    }
  }

  void _navigateToAddCategory() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddCategoryScreen()),
    );
    _loadCategories();
  }

  void _filterCategories(String query) {
    setState(() {
      _filteredCategories =
          _parentCategories
              .where(
                (category) =>
                    category.name.toLowerCase().contains(query.toLowerCase()),
              )
              .toList();
    });
  }

  void _editCategory(CategoryModel category) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddCategoryScreen(category: category),
      ),
    );

    if (result == true) {
      _loadCategories();
    }
  }

  void _confirmDeleteMultipleCategories() {
    if (_selectedCategories.isEmpty) return;
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Xác nhận xóa"),
            content: Text(
              "Bạn có chắc chắn muốn xóa ${_selectedCategories.length} danh mục không?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Hủy"),
              ),
              TextButton(
                onPressed: () async {
                  for (String id in _selectedCategories) {
                    await _categoryRepo.deleteCategory(id);
                  }
                  setState(() {
                    _isSelecting = false;
                    _selectedCategories.clear();
                    _loadCategories();
                  });
                  Navigator.pop(context);
                },
                child: const Text("Xóa", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color(0xFFBBDEFB)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: const BorderSide(color: Colors.blue),
                ),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      AppBar(
                        title: Text(
                          _isSelecting ? "Chọn danh mục" : "Quản lý danh mục",
                          style: const TextStyle(
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        flexibleSpace: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.blue, Colors.blueAccent],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                        centerTitle: true,
                        elevation: 0,
                        actions: _isSelecting
                            ? [
                                ScaleTransition(
                                  scale: _scaleAnimation,
                                  child: IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.white),
                                    onPressed: _confirmDeleteMultipleCategories,
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.blueAccent,
                                    ).copyWith(
                                      backgroundColor: MaterialStateProperty.resolveWith((states) {
                                        if (states.contains(MaterialState.hovered)) {
                                          return Colors.blue[700];
                                        }
                                        return Colors.blueAccent;
                                      }),
                                    ),
                                  ),
                                ),
                                ScaleTransition(
                                  scale: _scaleAnimation,
                                  child: IconButton(
                                    icon: const Icon(Icons.close, color: Colors.white),
                                    onPressed: () {
                                      setState(() {
                                        _isSelecting = false;
                                        _selectedCategories.clear();
                                      });
                                    },
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.blueAccent,
                                    ).copyWith(
                                      backgroundColor: MaterialStateProperty.resolveWith((states) {
                                        if (states.contains(MaterialState.hovered)) {
                                          return Colors.blue[700];
                                        }
                                        return Colors.blueAccent;
                                      }),
                                    ),
                                  ),
                                ),
                              ]
                            : [
                                ScaleTransition(
                                  scale: _scaleAnimation,
                                  child: IconButton(
                                    icon: const Icon(Icons.add, color: Colors.white),
                                    onPressed: _navigateToAddCategory,
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.blueAccent,
                                    ).copyWith(
                                      backgroundColor: MaterialStateProperty.resolveWith((states) {
                                        if (states.contains(MaterialState.hovered)) {
                                          return Colors.blue[700];
                                        }
                                        return Colors.blueAccent;
                                      }),
                                    ),
                                  ),
                                ),
                              ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 5,
                                height: 20,
                                color: Colors.blueAccent,
                                margin: const EdgeInsets.only(right: 10),
                              ),
                              const Text(
                                "Danh mục",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueAccent,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              ScaleTransition(
                                scale: _scaleAnimation,
                                child: IconButton(
                                  icon: Icon(
                                    Icons.list,
                                    color: !isGridView ? Colors.blueAccent : Colors.grey,
                                  ),
                                  onPressed: () => setState(() => isGridView = false),
                                ),
                              ),
                              ScaleTransition(
                                scale: _scaleAnimation,
                                child: IconButton(
                                  icon: Icon(
                                    Icons.grid_view,
                                    color: isGridView ? Colors.blueAccent : Colors.grey,
                                  ),
                                  onPressed: () => setState(() => isGridView = true),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.blue, width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 1,
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: _filterCategories,
                          decoration: const InputDecoration(
                            hintText: "Tìm kiếm danh mục...",
                            prefixIcon: Icon(Icons.search, color: Colors.blueAccent),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: _filteredCategories.isEmpty
                              ? const Center(
                                  child: Text("Không tìm thấy danh mục nào"),
                                )
                              : isGridView
                                  ? _buildGridView()
                                  : _buildListView(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(5),
      itemCount: _filteredCategories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.92,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (context, index) {
        final parent = _filteredCategories[index];
        final isSelected = _selectedCategories.contains(parent.id);
        return GestureDetector(
          onLongPress: () {
            setState(() {
              _isSelecting = true;
              _selectedCategories.add(parent.id!);
            });
          },
          onTap: () {
            if (_isSelecting) {
              setState(() {
                if (isSelected) {
                  _selectedCategories.remove(parent.id!);
                } else {
                  _selectedCategories.add(parent.id!);
                }
              });
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductListScreen(
                    categoryId: parent.id!,
                    categoryName: parent.name,
                  ),
                ),
              );
            }
          },
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Card(
              color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
               side: const BorderSide(color: Colors.blue),
              ),
              elevation: 3,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: ImageUtils.buildImage(parent.imageUrl),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    parent.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(height: 5),
                  if (_isSelecting)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ScaleTransition(
                          scale: _scaleAnimation,
                          child: Checkbox(
                            value: isSelected,
                            activeColor: Colors.blue,
                            onChanged: (selected) {
                              setState(() {
                                if (selected == true) {
                                  _selectedCategories.add(parent.id!);
                                } else {
                                  _selectedCategories.remove(parent.id!);
                                }
                              });
                            },
                          ),
                        ),
                        if (isSelected && _selectedCategories.length == 1)
                          ScaleTransition(
                            scale: _scaleAnimation,
                            child: IconButton(
                              icon: const Icon(Icons.edit, color: Colors.black),
                              onPressed: () => _editCategory(parent),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                              ).copyWith(
                                backgroundColor: MaterialStateProperty.resolveWith((states) {
                                  if (states.contains(MaterialState.hovered)) {
                                    return Colors.blue[700];
                                  }
                                  return Colors.blueAccent;
                                }),
                              ),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(5),
      itemCount: _filteredCategories.length,
      itemBuilder: (context, index) {
        final parent = _filteredCategories[index];
        final isSelected = _selectedCategories.contains(parent.id);

        return GestureDetector(
          onLongPress: () {
            setState(() {
              _isSelecting = true;
              _selectedCategories.add(parent.id!);
            });
          },
          onTap: () {
            if (_isSelecting) {
              setState(() {
                if (isSelected) {
                  _selectedCategories.remove(parent.id!);
                } else {
                  _selectedCategories.add(parent.id!);
                }
              });
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductListScreen(
                    categoryId: parent.id!,
                    categoryName: parent.name,
                  ),
                ),
              );
            }
          },
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Card(
              color: isSelected ? Colors.blue.withOpacity(0.5) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: Colors.blue),
              ),
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isSelecting)
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Checkbox(
                          value: isSelected,
                          activeColor: Colors.blue,
                          onChanged: (selected) {
                            setState(() {
                              if (selected == true) {
                                _selectedCategories.add(parent.id!);
                              } else {
                                _selectedCategories.remove(parent.id!);
                              }
                            });
                          },
                        ),
                      ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: ImageUtils.buildImage(parent.imageUrl),
                    ),
                  ],
                ),
                title: Text(
                  parent.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
                trailing: isSelected && _selectedCategories.length == 1
                    ? ScaleTransition(
                        scale: _scaleAnimation,
                        child: IconButton(
                          icon: const Icon(Icons.edit, color: Colors.black),
                          onPressed: () => _editCategory(parent),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                          ).copyWith(
                            backgroundColor: MaterialStateProperty.resolveWith((states) {
                              if (states.contains(MaterialState.hovered)) {
                                return Colors.blue[700];
                              }
                              return Colors.blueAccent;
                            }),
                          ),
                        ),
                      )
                    : null,
              ),
            ),
          ),
        );
      },
    );
  }
}