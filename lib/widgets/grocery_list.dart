import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart'
    as http; // все будет импортировано как объект http
import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/widgets/new_item.dart';

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItems = [];
  var _isLoading = true;
  String? _error;

// получаем список при первом рендере
  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() async {
    final url = Uri.https(
        'flutter-prep-acbe7-default-rtdb.firebaseio.com', 'shopping-list.json');

    try {
      final response = await http.get(url);

      if (response.statusCode >= 400) {
        setState(() {
          _error = 'Failed to fetch data  Please try again later.';
        });
      }

      if (response.body == 'null') {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final Map<String, dynamic> listData =
          json.decode(response.body); // конвертация полученных данных

      final List<GroceryItem> loadedItems = [];

      // цикл чтобы записать полученные данные в нужном формате
      for (final item in listData.entries) {
        final category = categories.entries
            .firstWhere(
                (catItem) => catItem.value.title == item.value['category'])
            .value; // ищем нужную категорию

        loadedItems.add(
          // добавили данные к общему списку
          GroceryItem(
            id: item.key,
            name: item.value['name'],
            quantity: item.value['quantity'],
            category: category,
          ),
        );
      }
      setState(() {
        _groceryItems = loadedItems; // добавили данные к существующему списку
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _error = 'Something went wrong! Please try again later.';
      });
    }
  }

  void _addItem() async {
    final newItem = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(
        builder: (ctx) => const NewItem(),
      ),
    );

    if (newItem == null) {
      return;
    }
    setState(() {
      _groceryItems.add(newItem);
    });
  }

  void _removeItem(GroceryItem item) async {
    final index = _groceryItems.indexOf(item); // получаем индекс айтема

    setState(() {
      _groceryItems.remove(item);
    });
    final url = Uri.https('flutter-prep-acbe7-default-rtdb.firebaseio.com',
        'shopping-list/${item.id}.json'); // включаем в роут айдишник

    final response = await http.delete(url);

    if (response.statusCode >= 400) {
      setState(() {
        _groceryItems.insert(
            index, item); // при ошибке возвразаем айтем на то же место
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = const Center(
      child: Text('No items added yet.'),
    );

    if (_isLoading) {
      content = const Center(child: CircularProgressIndicator());
    }

    if (_groceryItems.isNotEmpty) {
      content = ListView.builder(
        itemCount: _groceryItems.length,
        itemBuilder: (ctx, index) => Dismissible(
          onDismissed: (direction) {
            _removeItem(_groceryItems[index]);
          },
          key: ValueKey(_groceryItems[index].id),
          child: ListTile(
            title: Text(_groceryItems[index].name),
            leading: Container(
              width: 24,
              height: 24,
              color: _groceryItems[index].category.color,
            ),
            trailing: Text(
              _groceryItems[index].quantity.toString(),
            ),
          ),
        ),
      );
    }
    if (_error != null) {
      content = Center(
        child: Text(_error!),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Groceries'),
        actions: [
          IconButton(
            onPressed: _addItem,
            icon: const Icon(Icons.add),
          )
        ],
      ),
      body: content,
    );
  }
}

// // вариант с FutureBuilder
// class _GroceryListState extends State<GroceryList> {
//   final List<GroceryItem> _groceryItems = [];
//   late Future<List<GroceryItem>> _loadedItems;

//   @override
//   void initState() {
//     super.initState();
//     _loadedItems = _loadItems(); // записываем Future в переменную
//   }

// // возвразаем Future
//   Future<List<GroceryItem>> _loadItems() async {
//     final url = Uri.https(
//         'flutter-prep-acbe7-default-rtdb.firebaseio.com', 'shopping-list.json');

//     final response = await http.get(url);

//     if (response.statusCode >= 400) {
//       throw Exception('Failed to fetch  Please try later.');
//     }

//     if (response.body == 'null') {
//       return [];
//     }

//     final Map<String, dynamic> listData = json.decode(response.body);

//     final List<GroceryItem> loadedItems = [];

//     for (final item in listData.entries) {
//       final category = categories.entries
//           .firstWhere(
//               (catItem) => catItem.value.title == item.value['category'])
//           .value;

//       loadedItems.add(
//         GroceryItem(
//           id: item.key,
//           name: item.value['name'],
//           quantity: item.value['quantity'],
//           category: category,
//         ),
//       );
//     }
//     return loadedItems;
//   }

//   void _addItem() async {
//     final newItem = await Navigator.of(context).push<GroceryItem>(
//       MaterialPageRoute(
//         builder: (ctx) => const NewItem(),
//       ),
//     );

//     if (newItem == null) {
//       return;
//     }
//     setState(() {
//       _groceryItems.add(newItem);
//     });
//   }

//   void _removeItem(GroceryItem item) async {
//     final index = _groceryItems.indexOf(item);

//     setState(() {
//       _groceryItems.remove(item);
//     });
//     final url = Uri.https('flutter-prep-acbe7-default-rtdb.firebaseio.com',
//         'shopping-list/${item.id}.json');

//     final response = await http.delete(url);

//     if (response.statusCode >= 400) {
//       setState(() {
//         _groceryItems.insert(index, item);
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Your Groceries'),
//         actions: [
//           IconButton(
//             onPressed: _addItem,
//             icon: const Icon(Icons.add),
//           )
//         ],
//       ),
//       body: FutureBuilder(
//         future:
//             _loadedItems, // хорошая практика не передавать сюда вызов фунцкии, а использовать initialState
//         builder: (context, snapshot) {
//           // loading
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           // error
//           if (snapshot.hasError) {
//             return Center(child: Text(snapshot.error.toString()));
//           }

//           // empty
//           if (snapshot.data!.isEmpty) {
//             return const Center(child: Text('No items added yet.'));
//           }

//           return ListView.builder(
//             itemCount: snapshot.data!.length,
//             itemBuilder: (ctx, index) => Dismissible(
//               onDismissed: (direction) {
//                 _removeItem(snapshot.data![index]);
//               },
//               key: ValueKey(snapshot.data![index].id),
//               child: ListTile(
//                 title: Text(snapshot.data![index].name),
//                 leading: Container(
//                   width: 24,
//                   height: 24,
//                   color: snapshot.data![index].category.color,
//                 ),
//                 trailing: Text(
//                   snapshot.data![index].quantity.toString(),
//                 ),
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
