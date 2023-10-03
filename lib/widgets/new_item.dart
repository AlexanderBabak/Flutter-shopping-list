import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart'
    as http; // все будет импортировано как объект http
import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/models/category.dart';
import 'package:shopping_list/models/grocery_item.dart';

class NewItem extends StatefulWidget {
  const NewItem({super.key});

  @override
  State<NewItem> createState() => _NewItemState();
}

class _NewItemState extends State<NewItem> {
  final _formKey = GlobalKey<FormState>(); // ключ для Form
  var _enteredName = ''; // данные из инпута
  var _enteredQuantity = 1; // данные из инпута
  var _selectedCategory = categories[Categories.vegetables]!;
  var _isSending = false;

  void _saveItem() async {
    // _formKey.currentState!.validate(); // вызывает валидацию, возвращает boolean
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save(); // сохраняет введенные в инпуты значения
      setState(() {
        _isSending = true;
      });
      final url = Uri.https('flutter-prep-acbe7-default-rtdb.firebaseio.com',
          'shopping-list.json'); // настройки URL и дополнительный path

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'aplication/json',
        },
        body: json.encode(
          {
            // конвертим в json
            'name': _enteredName,
            'quantity': _enteredQuantity,
            'category': _selectedCategory.title,
          },
        ),
      );

      final Map<String, dynamic> resData = json.decode(response.body);

      // проверка конткеста
      if (!context.mounted) {
        return;
      }

      Navigator.of(context).pop(
        GroceryItem(
            id: resData['name'],
            name: _enteredName,
            quantity: _enteredQuantity,
            category: _selectedCategory),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add a new item'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _formKey, // для работы валидации
          child: Column(
            children: [
              TextFormField(
                maxLength: 50,
                decoration: const InputDecoration(
                  label: Text('Name'),
                ),
                validator: (value) {
                  if (value == null ||
                      value.isEmpty ||
                      value.trim().length <= 1 ||
                      value.trim().length > 50) {
                    return 'Error message';
                  }
                  return null;
                },
                onSaved: (value) {
                  // здесь получаем доступ к значению и можем делать с ним манипуляции
                  _enteredName = value!;
                },
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        label: Text('Quantity'),
                      ),
                      initialValue: _enteredQuantity
                          .toString(), // можно только в таком виджете
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty ||
                            int.tryParse(value) == null ||
                            int.tryParse(value)! <= 0) {
                          return 'Must be a valid positive number.';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _enteredQuantity = int.parse(value!);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField(
                      value: _selectedCategory, // initialValue
                      items: [
                        // конвертация map в list categories.entries
                        for (final category in categories.entries)
                          DropdownMenuItem(
                              value: category.value,
                              child: Row(
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    color: category.value.color,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(category.value.title),
                                ],
                              )),
                      ],
                      onChanged: (value) {
                        // используем setState чтобы перерисовать UI
                        setState(() {
                          _selectedCategory =
                              value!; // меняем выбранное значение
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSending
                        ? null
                        : () {
                            _formKey.currentState!.reset(); // сбрасываем форму
                          },
                    child: const Text('Reset'),
                  ),
                  ElevatedButton(
                    onPressed:
                        _isSending ? null : _saveItem, // сохраняем данные
                    child: _isSending
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(),
                          )
                        : const Text('Add item'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
