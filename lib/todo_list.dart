// ignore_for_file: prefer_final_fields, prefer_const_constructors, prefer_const_literals_to_create_immutables, prefer_collection_literals, unused_field, prefer_void_to_null, curly_braces_in_flow_control_structures

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class TodoList extends StatefulWidget {
  const TodoList({Key? key}) : super(key: key);

  @override
  State<TodoList> createState() => _TodoListState();
}

class _TodoListState extends State<TodoList> {
  final _toDoController = TextEditingController();
  List _toDoList = [];
  late Map<String, dynamic> _lastRemoved;
  late int _lastRemovedPosition;

  @override
  void initState() {
    super.initState();
    _readData().then((data) {
      setState(() {
        _toDoList = json.decode(data!);
      });
    });
  }

  void _addToDo() {
    setState(() {
      Map<String, dynamic> newToDo = Map();
      newToDo["title"] = _toDoController.text;
      _toDoController.text = "";
      newToDo["status"] = false;
      _toDoList.add(newToDo);
      _saveData();
    });
  }

  Future<Null> _refresh() async {
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      _toDoList.sort((a, b) {
        if (a["status"] && !b["status"])
          return 1;
        else if (!a["status"] && b["status"])
          return -1;
        else
          return 0;
      });
      _saveData();
    });
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("To Do List"),
        backgroundColor: Colors.purpleAccent,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(15.0, 5.0, 15.0, 5.0),
            child: Row(
              children: [
                Expanded(
                  child: Form(
                    child: TextFormField(
                      controller: _toDoController,
                      decoration: InputDecoration(
                        labelText: "Nova Tarefa",
                        labelStyle: TextStyle(color: Colors.purpleAccent),
                      ),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: _addToDo,
                  child: Icon(Icons.add),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                padding: EdgeInsets.all(10.0),
                itemCount: _toDoList.length,
                itemBuilder: buildItem,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildItem(context, index) {
    return Dismissible(
      key: Key(DateTime.now().microsecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(Icons.delete, color: Colors.white),
        ),
      ),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        title: Text(_toDoList[index]["title"]),
        value: _toDoList[index]["status"],
        secondary: CircleAvatar(
          child: Icon(_toDoList[index]["status"] ? Icons.check : Icons.error),
        ),
        onChanged: (changed) {
          setState(() {
            _toDoList[index]["status"] = changed;
            _saveData();
          });
        },
      ),
      onDismissed: (direction) {
        setState(() {
          _lastRemoved = Map.from(_toDoList[index]);
          _lastRemovedPosition = index;
          _toDoList.removeAt(index);
          _saveData();
          final snack = SnackBar(
            content: Text("Tarefa ${_lastRemoved["title"]} removida!"),
            action: SnackBarAction(
                label: "Desfazer",
                onPressed: () {
                  setState(() {
                    _toDoList.insert(_lastRemovedPosition, _lastRemoved);
                    _saveData();
                  });
                }),
            duration: Duration(seconds: 3),
          );

          ScaffoldMessenger.of(context).removeCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(snack);
        });
      },
    );
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  Future<File> _saveData() async {
    String data = json.encode(_toDoList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String?> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (e) {
      return null;
    }
  }
}
