import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:english_words/english_words.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Save Favorite List - Shared Preferences',
        theme: ThemeData(
          brightness: Brightness.dark,
          primaryColor: Colors.purple,
          colorScheme: ThemeData().colorScheme.copyWith(
                secondary: Colors.amber,
                brightness:
                    Brightness.dark, // match with ThemeData's brightness
              ),
          fontFamily: 'Montserrat',
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  var current = WordPair.random();
  List<WordPair> favorites = [];

  void getNext() {
    current = WordPair.random();
    notifyListeners();
  }

  Future<void> toggleFavorite() async {
    if (favorites.contains(current)) {
      favorites.remove(current);
    } else {
      favorites.add(current);
      try {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        final favs = prefs.getStringList('Favorite') ?? [];
        final List<String> favWords =
            favorites.map((pair) => '${pair.first}${pair.second}').toList();
        favs.add(favWords.toString());
        await prefs.setStringList('Favorite', favs);
        favWords.clear();
      } catch (e) {
        SharedPreferences.setMockInitialValues({});
      }
    }
    notifyListeners();
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = GeneratorPage();
        break;
      case 1:
        page = FavoritesPage();
        break;
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }

    return LayoutBuilder(builder: (context, constraints) {
      return Scaffold(
        body: Row(
          children: [
            SafeArea(
              child: NavigationRail(
                extended: constraints.maxWidth >= 600,
                destinations: [
                  NavigationRailDestination(
                    icon: Icon(Icons.home, color: Colors.purple),
                    label: Text('Home', style: TextStyle(color: Colors.purple)),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.favorite, color: Colors.amber),
                    label: Text('Favorites',
                        style: TextStyle(color: Colors.amber)),
                  ),
                ],
                selectedIndex: selectedIndex,
                onDestinationSelected: (value) {
                  setState(() {
                    selectedIndex = value;
                  });
                },
              ),
            ),
            Expanded(
              child: Container(
                color: Theme.of(context).primaryColor,
                child: page,
              ),
            ),
          ],
        ),
      );
    });
  }
}

class GeneratorPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var pair = appState.current;

    IconData icon;
    if (appState.favorites.contains(pair)) {
      icon = Icons.favorite;
    } else {
      icon = Icons.favorite_border;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          BigCard(pair: pair),
          SizedBox(height: 20),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  appState.toggleFavorite();
                },
                icon: Icon(icon, color: Colors.white),
                label: Text('Like', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  primary: Colors.purple,
                ),
              ),
              SizedBox(width: 20),
              ElevatedButton(
                onPressed: () {
                  appState.getNext();
                },
                child: Text('Next', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  primary: Colors.amber,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class BigCard extends StatelessWidget {
  const BigCard({Key? key, required this.pair}) : super(key: key);

  final WordPair pair;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.displayMedium!.copyWith(
      color: theme.colorScheme.onPrimary,
    );

    return Card(
      color: theme.primaryColor,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          pair.asLowerCase,
          style: style,
          semanticsLabel: "${pair.first} ${pair.second}",
        ),
      ),
    );
  }
}

class FavoritesPage extends StatelessWidget {
  void _getFav() async {
    final prefs = await SharedPreferences.getInstance();
    print(prefs.getStringList(('Favorite')));
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    if (appState.favorites.isEmpty) {
      return Center(
        child: Text('No favorites yet',
            style: TextStyle(color: Colors.amber, fontSize: 18.0)),
      );
    } else if (appState.favorites.isNotEmpty) {
      _getFav();
    }

    return ListView(
      children: [
        Padding(
          padding: EdgeInsets.all(20),
          child: Text('You have ${appState.favorites.length} favorites:',
              style: TextStyle(color: Colors.white, fontSize: 18.0)),
        ),
        for (var pair in appState.favorites)
          ListTile(
            leading: Icon(Icons.favorite, color: Colors.amber),
            title: Text(pair.asLowerCase,
                style: TextStyle(color: Colors.white, fontSize: 18.0)),
          )
      ],
    );
  }
}
