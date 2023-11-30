import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:grocery_app/data/categories.dart';
import 'package:grocery_app/models/grocery_item.dart';
import 'package:grocery_app/widget/new_item.dart';
import "package:http/http.dart" as http;

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItems = [];
  var _isLoading = true;
  var _isError = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() async {
    final url = Uri.https(
        "flutter-prep-3d19c-default-rtdb.firebaseio.com", "shopping-list.json");
    final response = await http.get(url);
    print(response.statusCode);
    final Map<String, dynamic> listData = json.decode(response.body);
    final List<GroceryItem> loadedItems = [];
    for (final item in listData.entries) {
      final category = categories.entries
          .firstWhere(
              (catItem) => catItem.value.title == item.value["category"])
          .value;
      loadedItems.add(
        GroceryItem(
          id: item.key,
          name: item.value["name"],
          quantity: item.value["quantity"],
          category: category,
        ),
      );
    }
    setState(() {
      _groceryItems = loadedItems;
      _isLoading = false;
      _isError = false;
    });
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

  void _removeItem(GroceryItem item) {
    final url = Uri.https("flutter-prep-3d19c-default-rtdb.firebaseio.com",
        "shopping-list/${item.id}.json");
    http.delete(url);
    setState(() {
      _groceryItems.remove(item);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Your groceries"),
        actions: [IconButton(onPressed: _addItem, icon: const Icon(Icons.add))],
      ),
      body: _isError
          ? const Center(child: Text("Sorry error"))
          : _isLoading
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : _groceryItems.isEmpty
                  ? const Center(child: Text("No item yet"))
                  : ListView.builder(
                      itemCount: _groceryItems.length,
                      itemBuilder: (context, index) => Dismissible(
                        onDismissed: (direction) {
                          _removeItem(
                            _groceryItems[index],
                          );
                        },
                        key: ValueKey(_groceryItems[index].id),
                        child: ListTile(
                          title: Text(_groceryItems[index].name),
                          leading: Container(
                            width: 24,
                            height: 24,
                            color: _groceryItems[index].category.color,
                          ),
                          trailing:
                              Text(_groceryItems[index].quantity.toString()),
                        ),
                      ),
                    ),
    );
  }
}
