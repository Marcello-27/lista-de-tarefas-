import 'dart:convert'; // Adicione esta importação
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:lista/models/todo.dart';
import 'package:lista/widgets/todo_list_item.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TodoListPage extends StatefulWidget {
  const TodoListPage({super.key});

  @override
  _TodoListPageState createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> {
  List<Todo> todos = [];
  Todo? recentlyDeletedTodo;
  final TextEditingController todoController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    _loadTasks(); // Carregar tarefas salvas ao iniciar
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? todoString = prefs.getString('todos');
    if (todoString != null) {
      final List<dynamic> todoJsonList = jsonDecode(todoString);
      setState(() {
        todos = todoJsonList.map((json) => Todo.fromJson(json)).toList();
      });
    }
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> todoJsonList =
    todos.map((todo) => todo.toJson()).toList();
    final String todoString = jsonEncode(todoJsonList);
    await prefs.setString('todos', todoString);
  }

  void _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate)
      setState(() {
        _selectedDate = picked;
      });
  }

  void _selectTime() async {
    final TimeOfDay? picked = await showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoTimerPicker(
        mode: CupertinoTimerPickerMode.hm,
        initialTimerDuration: Duration(
          hours: _selectedTime.hour,
          minutes: _selectedTime.minute,
        ),
        onTimerDurationChanged: (duration) {
          setState(() {
            _selectedTime = TimeOfDay(
              hour: duration.inHours,
              minute: duration.inMinutes % 60,
            );
          });
        },
      ),
    );
    if (picked != null && picked != _selectedTime)
      setState(() {
        _selectedTime = picked;
      });
  }

  void _addTask() {
    final text = todoController.text;
    if (text.isNotEmpty) {
      final dateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );
      setState(() {
        Todo newTodo = Todo(
          title: text,
          dateTime: dateTime,
        );
        todos.add(newTodo);
        _saveTasks(); // Salvar tarefas após adicionar
      });
      todoController.clear();
    }
  }

  void _confirmClearAllTasks() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmação'),
          content: Text('Você tem certeza de que deseja excluir todas as tarefas?'),
          actions: [
            TextButton(
              child: Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Excluir Tudo'),
              onPressed: () {
                Navigator.of(context).pop(); // Fecha o diálogo
                _clearAllTasks(); // Limpa as tarefas
              },
            ),
          ],
        );
      },
    );
  }

  void _clearAllTasks() {
    setState(() {
      todos.clear();
      recentlyDeletedTodo = null;
      _saveTasks(); // Salvar estado limpo após excluir todas as tarefas
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.list),
            SizedBox(width: 8),
            Text('Lista de Tarefas'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_forever),
            onPressed: _confirmClearAllTasks, // Atualizado para confirmar antes de limpar
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal[200]!, Colors.teal[700]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: todoController,
                  decoration: InputDecoration(
                    hintText: 'Nova Tarefa', // Adiciona o texto de dica no campo
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white38.withOpacity(0.9),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    onPressed: _selectDate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal[500],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      'Data: ${DateFormat.yMd().format(_selectedDate)}',
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _selectTime,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal[500],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      'Hora: ${_selectedTime.format(context)}',
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _addTask,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal[600],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Adicionar Tarefa'),
                  ),
                ],
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: todos.length,
                  itemBuilder: (context, index) {
                    return TodoListItem(
                      todo: todos[index],
                      onDelete: (todo, {undo = false}) {
                        if (!undo) {
                          setState(() {
                            recentlyDeletedTodo = todo;
                            todos.remove(todo);
                            _saveTasks(); // Salvar tarefas após exclusão
                          });
                        } else {
                          setState(() {
                            todos.add(recentlyDeletedTodo!);
                            recentlyDeletedTodo = null;
                            _saveTasks(); // Salvar tarefas após desfazer exclusão
                          });
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Tarefas Pendentes: ${todos.length}',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
