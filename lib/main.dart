import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(1280, 720),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    minimumSize: Size(640, 360),
    title: '单词管理器',
    titleBarStyle: TitleBarStyle.hidden, // 隐藏默认标题栏
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.setAsFrameless();
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '单词管理器',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'PingFang SC',
        appBarTheme: const AppBarTheme(
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(
              color: Color.fromARGB(255, 64, 64, 64),
              fontSize: 20,
              fontFamily: 'PingFang SC'),
        ),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;
  bool _showIconsOnly = false;
  bool _showText = true;
  final TextEditingController _wordController = TextEditingController();
  final TextEditingController _meaningController = TextEditingController();
  final List<String> _selectedTypes = [];
  String appBarTitle = '单词管理器';

  @override
  void initState() {
    super.initState();
    _createAppDataDir();
  }

  Future<void> _createAppDataDir() async {
    final directory = await _getAppDataDirectory();
    if (!await directory.exists()) {
      await directory.create();
    }
  }

  Future<Directory> _getAppDataDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    if (!await Directory('${directory.path}/words_manager').exists()) {
      await Directory('${directory.path}/words_manager').create();
    }
    return Directory('${directory.path}/words_manager');
  }

  Future<void> _addWord(String word, String? meaning, List<String> types,
      {bool favorite = false}) async {
    if (word.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
              '单词不能为空',
              style: TextStyle(color: Color.fromARGB(255, 64, 64, 64)),
            ),
            backgroundColor: Color.fromARGB(255, 232, 223, 238),
            duration: Duration(seconds: 1)),
      );
      return;
    }

    final directory = await _getAppDataDirectory();
    final file = File('${directory.path}/$word');

    if (await file.exists()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
              '不能有相同的单词',
              style: TextStyle(color: Color.fromARGB(255, 64, 64, 64)),
            ),
            backgroundColor: Color.fromARGB(255, 232, 223, 238),
            duration: Duration(seconds: 1)),
      );
      return;
    }

    await file.writeAsString(
        '$word\n${meaning ?? ''}\n${types.join(' ')}\n$favorite');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text(
            '单词添加成功',
            style: TextStyle(color: Color.fromARGB(255, 64, 64, 64)),
          ),
          backgroundColor: Color.fromARGB(255, 232, 223, 238),
          duration: Duration(seconds: 1)),
    );
    setState(() {}); // 刷新页面
  }

  Future<void> _removeWord(String word) async {
    final directory = await _getAppDataDirectory();
    final file = File('${directory.path}/$word');
    if (await file.exists()) {
      await file.delete();
    }
    setState(() {}); // 刷新页面
  }

  Future<void> _toggleFavorite(String word) async {
    final directory = await _getAppDataDirectory();
    final file = File('${directory.path}/$word');
    if (await file.exists()) {
      final lines = await file.readAsLines();
      final isFavorite = lines[3] == 'true';
      lines[3] = (!isFavorite).toString();
      await file.writeAsString(lines.join('\n'));
      setState(() {}); // 刷新页面
    }
  }

  Future<List<Map<String, dynamic>>> _loadWords(
      {bool favoriteOnly = false}) async {
    final directory = await _getAppDataDirectory();
    final files = directory.listSync();
    final words = <Map<String, dynamic>>[];

    for (var file in files) {
      if (file is File) {
        final lines = await file.readAsLines();
        final word = {
          'word': lines[0],
          'meaning': lines[1],
          'types': lines[2].split(' '),
          'favorite': lines[3] == 'true',
        };
        if (!favoriteOnly || word['favorite'] == true) {
          words.add(word);
        }
      }
    }
    return words;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;

      switch (index) {
        case 0:
          appBarTitle = '单词管理器 - 首页';
          windowManager.setTitle('单词管理器 - 首页');
          break;
        case 1:
          appBarTitle = '单词管理器 - 新单词';
          windowManager.setTitle('单词管理器 - 新单词');
          break;
        case 2:
          appBarTitle = '单词管理器 - 收藏';
          windowManager.setTitle('单词管理器 - 收藏');
          break;
        case 3:
          appBarTitle = '单词管理器 - 搜索';
          windowManager.setTitle('单词管理器 - 搜索');
          break;
        default:
          appBarTitle = '单词管理器';
          windowManager.setTitle('单词管理器');
      }
    });
  }

  void _toggleShowIconsOnly() {
    setState(() {
      _showIconsOnly = !_showIconsOnly;
      if (!_showIconsOnly) {
        Future.delayed(const Duration(milliseconds: 200), () {
          setState(() {
            _showText = true;
          });
        });
      } else {
        _showText = false;
      }
    });
  }

  Future<void> _confirmDeleteWord(String word) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('确认删除'),
          content: Text('你确定要删除单词 "$word" 吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      await _removeWord(word);
      setState(() {}); // 刷新页面
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> _pages = <Widget>[
      _buildHomePage(),
      _buildNewWordPage(),
      _buildFavoriteWordsPage(),
      _buildSearchPage(), // 添加搜索页面
    ];

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.purple, width: 0.5), // 添加紫色边框
      ),
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(50.0),
          child: GestureDetector(
            onPanStart: (details) {
              windowManager.startDragging();
            },
            child: AppBar(
              title: Text(appBarTitle), // 使用变量来设置标题
              backgroundColor:
                  const Color.fromARGB(255, 242, 231, 250), // 固定背景颜色
              actions: [
                IconButton(
                  icon: const Icon(Icons.remove, color: Colors.blue),
                  onPressed: () {
                    windowManager.minimize();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.crop_square, color: Colors.blue),
                  onPressed: () {
                    windowManager.isMaximized().then((isMaximized) {
                      if (isMaximized) {
                        windowManager.unmaximize();
                      } else {
                        windowManager.maximize();
                      }
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.blue),
                  onPressed: () {
                    windowManager.close();
                  },
                ),
                const SizedBox(width: 5)
              ],
            ),
          ),
        ),
        body: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _showIconsOnly ? 70 : 250,
              child: Drawer(
                child: Container(
                  child: Column(
                    children: <Widget>[
                      ListTile(
                        leading: const Icon(Icons.menu, color: Colors.blue),
                        title: _showText ? const Text('只显示图标') : null,
                        onTap: _toggleShowIconsOnly,
                      ),
                      Expanded(
                        child: ListView(
                          padding: EdgeInsets.zero,
                          children: <Widget>[
                            ListTile(
                              leading:
                                  const Icon(Icons.home, color: Colors.blue),
                              title: _showText ? const Text('首页') : null,
                              selected: _selectedIndex == 0,
                              tileColor: _selectedIndex == 0
                                  ? Colors.lightBlueAccent
                                  : null,
                              onTap: () => _onItemTapped(0),
                            ),
                            ListTile(
                              leading:
                                  const Icon(Icons.add, color: Colors.blue),
                              title: _showText ? const Text('新单词') : null,
                              selected: _selectedIndex == 1,
                              tileColor: _selectedIndex == 1
                                  ? Colors.lightBlueAccent
                                  : null,
                              onTap: () => _onItemTapped(1),
                            ),
                            ListTile(
                              leading: const Icon(Icons.favorite,
                                  color: Colors.blue),
                              title: _showText ? const Text('收藏') : null,
                              selected: _selectedIndex == 2,
                              tileColor: _selectedIndex == 2
                                  ? Colors.lightBlueAccent
                                  : null,
                              onTap: () => _onItemTapped(2),
                            ),
                            ListTile(
                              leading: const Icon(Icons.search,
                                  color: Colors.blue), // 添加搜索图标
                              title: _showText ? const Text('搜索') : null,
                              selected: _selectedIndex == 3,
                              tileColor: _selectedIndex == 3
                                  ? Colors.lightBlueAccent
                                  : null,
                              onTap: () => _onItemTapped(3), // 点击跳转到搜索页面
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Container(
                color: Colors.white,
                child: _pages[_selectedIndex],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomePage() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _loadWords(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final words = snapshot.data!;
        if (words.isEmpty) {
          return const Center(
            child: Text(
              '这里什么也没有~',
              style: TextStyle(fontSize: 24, color: Colors.grey),
            ),
          );
        }
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                '单词总数: ${words.length}',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: words.length,
                itemBuilder: (context, index) {
                  final word = words[index];
                  final types = word['meaning'].isNotEmpty
                      ? ' ${word['types'].join(' ')}'
                      : '${word['types'].join(' ')}';
                  return ListTile(
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          word['word']!,
                          style:
                              const TextStyle(fontSize: 24, color: Colors.blue),
                        ),
                        if (word['meaning']!.isNotEmpty || types.isNotEmpty)
                          Text(
                            '${word['meaning']!}$types',
                            style: const TextStyle(
                                fontSize: 16, color: Colors.grey),
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            word['favorite']
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: word['favorite'] ? Colors.red : null,
                          ),
                          onPressed: () => _toggleFavorite(word['word']!),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.blue),
                          onPressed: () => _confirmDeleteWord(word['word']!),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNewWordPage() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _wordController,
            decoration: const InputDecoration(
                labelText: '输入新单词',
                icon: Icon(Icons.language, color: Colors.blue)),
          ),
          TextField(
            controller: _meaningController,
            decoration: const InputDecoration(
                labelText: '输入中文意思（选填）',
                icon: Icon(Icons.translate, color: Colors.blue)),
          ),
          const SizedBox(height: 20), // 添加间距
          Wrap(
            spacing: 10.0,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 5.0),
                child: Text('词性：', style: TextStyle(fontSize: 15)),
              ),
              _buildCheckbox('n.'),
              _buildCheckbox('pron.'),
              _buildCheckbox('adj.'),
              _buildCheckbox('num.'),
              _buildCheckbox('v.'),
              _buildCheckbox('adv.'),
              _buildCheckbox('art.'),
              _buildCheckbox('prep.'),
              _buildCheckbox('conj.'),
              _buildCheckbox('int.'),
            ],
          ),
          const SizedBox(height: 20), // 添加间距
          ElevatedButton.icon(
            onPressed: () {
              _addWord(_wordController.text, _meaningController.text,
                  List<String>.from(_selectedTypes));
              _wordController.clear();
              _meaningController.clear();
              _selectedTypes.clear();
            },
            style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(
                    const Color.fromARGB(255, 221, 245, 255))),
            icon: const Icon(Icons.add, color: Colors.blue),
            label: const Text(
              '添加单词',
              style: TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckbox(String type) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: _selectedTypes.contains(type),
          onChanged: (bool? value) {
            setState(() {
              if (value == true) {
                _selectedTypes.add(type);
              } else {
                _selectedTypes.remove(type);
              }
            });
          },
          checkColor: Colors.lightBlue[100],
          activeColor: Colors.blue,
          side: const BorderSide(width: 1, color: Colors.blue),
        ),
        Text(type),
      ],
    );
  }

  Widget _buildFavoriteWordsPage() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _loadWords(favoriteOnly: true),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final words = snapshot.data!;
        if (words.isEmpty) {
          return const Center(
            child: Text(
              '这里什么也没有~',
              style: TextStyle(fontSize: 24, color: Colors.grey),
            ),
          );
        }
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                '收藏总数: ${words.length}',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: words.length,
                itemBuilder: (context, index) {
                  final word = words[index];
                  final types = word['meaning'].isNotEmpty
                      ? ' ${word['types'].join(' ')}'
                      : '${word['types'].join(' ')}';
                  return ListTile(
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          word['word']!,
                          style:
                              const TextStyle(fontSize: 24, color: Colors.blue),
                        ),
                        if (word['meaning']!.isNotEmpty || types.isNotEmpty)
                          Text(
                            '${word['meaning']!}$types',
                            style: const TextStyle(
                                fontSize: 16, color: Colors.grey),
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            word['favorite']
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: word['favorite'] ? Colors.red : null,
                          ),
                          onPressed: () => _toggleFavorite(word['word']!),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.blue),
                          onPressed: () => _confirmDeleteWord(word['word']!),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchPage() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: '搜索单词',
                    icon: Icon(Icons.search, color: Colors.blue),
                  ),
                  onChanged: (query) {
                    setState(() {
                      _searchQuery = query;
                    });
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.clear, color: Colors.blue),
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                  });
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _loadWords(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final words = snapshot.data!
                  .where((word) =>
                      word['word'].contains(_searchQuery) ||
                      word['meaning'].contains(_searchQuery))
                  .toList();
              if (words.isEmpty) {
                return const Center(
                  child: Text(
                    '没有匹配的单词~',
                    style: TextStyle(fontSize: 24, color: Colors.grey),
                  ),
                );
              }
              return ListView.builder(
                itemCount: words.length,
                itemBuilder: (context, index) {
                  final word = words[index];
                  final types = word['meaning'].isNotEmpty
                      ? ' ${word['types'].join(' ')}'
                      : '${word['types'].join(' ')}';
                  return ListTile(
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          word['word']!,
                          style:
                              const TextStyle(fontSize: 24, color: Colors.blue),
                        ),
                        if (word['meaning']!.isNotEmpty || types.isNotEmpty)
                          Text(
                            '${word['meaning']!}$types',
                            style: const TextStyle(
                                fontSize: 16, color: Colors.grey),
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            word['favorite']
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: word['favorite'] ? Colors.red : null,
                          ),
                          onPressed: () => _toggleFavorite(word['word']!),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.blue),
                          onPressed: () => _confirmDeleteWord(word['word']!),
                        ),
                      ],
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

  String _searchQuery = '';
}
