import 'package:dictionaryx/dictentry.dart';
import 'package:dictionaryx/dictionary_msa_json_flutter.dart';

import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Namer App',
        theme: ThemeData(
          useMaterial3: true,
          // select the theme color
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  // current word pair being diplayed
  var current = WordPair.random();
  // list of all of the word pairs that were favorited
  var favorites = <WordPair>[];

  // generate a new word pair
  void getNext() {
    current = WordPair.random();
    notifyListeners();
  }

  // control for the current word pair for the favorites list
  void toggleFavorite() {
    // if the favorites list contains the current word pair, remove it,
    // otherwise add it
    if (favorites.contains(current)) {
      favorites.remove(current);
    } else {
      favorites.add(current);
    }
    notifyListeners();
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Selected page, default is the home page
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (selectedIndex) {
      // home page
      case 0:
        page = GeneratorPage();
        break;
      // favorites page
      case 1:
        page = FavoritesPage();
        break;
      // error
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }
    return LayoutBuilder(builder: (context, constraints) {
      return Scaffold(
        body: Row(
          children: [
            SafeArea(
              child: NavigationRail(
                backgroundColor: Colors.black,
                extended: constraints.maxWidth >= 600,
                leading: Container(
                  color: Colors.white,
                  width: 260,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    // load the logo
                    child: Image.asset(
                      '../assets/evosus_logo_sm.png',
                      height: 17.72,
                      width: 100,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                destinations: [
                  // home page icon navigation
                  NavigationRailDestination(
                    icon: Icon(Icons.home, color: Colors.orange),
                    label: Text(
                      'Home',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  // favoties page icon navigation
                  NavigationRailDestination(
                    icon: Icon(
                      Icons.hot_tub,
                      color: Colors.orange,
                    ),
                    label: Text(
                      'Favorites',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
                selectedIndex: selectedIndex,
                onDestinationSelected: (value) {
                  // if a destination has been changed, update the page
                  setState(
                    () {
                      selectedIndex = value;
                    },
                  );
                },
              ),
            ),
            // display the main content of the page
            Expanded(
              child: Container(
                color: Colors.white,
                child: page,
              ),
            ),
          ],
        ),
      );
    });
  }
}

// Build the favorites page
Future buildFavoriteView(BuildContext context) async {
  var appState = context.watch<MyAppState>();

  // if the page is emtpy, return an empty message
  if (appState.favorites.isEmpty) {
    return Center(
      child: Text('No favorites yet.'),
    );
  }

  // create a list of children to put into ListView to return
  List<Widget> listViewChildren = [
    // header
    Padding(
      padding: const EdgeInsets.all(20),
      child: Text('You have '
          '${appState.favorites.length} favorites:'),
    ),
  ];

  // for every word pair the user has favorited
  for (var pair in appState.favorites) {
    // send an loop up request for each of the words in the word pair
    DictEntry dictDefinition1 =
        await DictionaryMSAFlutter().getEntry(pair.first);
    DictEntry dictDefinition2 =
        await DictionaryMSAFlutter().getEntry(pair.second);

    // get the first definition found
    String definition1 = dictDefinition1.meanings.first.description;
    String definition2 = dictDefinition2.meanings.first.description;

    // generate a ListTile
    listViewChildren.add(
      ListTile(
        leading: Icon(Icons.hot_tub),
        title: Tooltip(
          message: '$definition1' '  +  ' '$definition2',
          child: Text(pair.asLowerCase),
        ),
      ),
    );
  }

  return ListView(
    children: listViewChildren,
  );
}

class FavoritesPage extends StatefulWidget {
  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  @override
  Widget build(BuildContext context) {
    return favoriteView(context);
  }
}

// Generate the favorite view
FutureBuilder favoriteView(BuildContext context) {
  return FutureBuilder(
    future: buildFavoriteView(context),
    builder: (BuildContext context, AsyncSnapshot snapshot) {
      // if there is delay in displaying the page, show a circular progress icon
      if (snapshot.hasData) {
        return snapshot.data;
      } else if (snapshot.hasError) {
        return Text("Error: ${snapshot.error}");
      } else {
        return const CircularProgressIndicator();
      }
    },
  );
}

class GeneratorPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // watch the context for updates to refresh the state
    var appState = context.watch<MyAppState>();
    var pair = appState.current;

    // if the wordpair is favorited, display a hot_tub
    // if the wordpair is not favorited, display a pool
    IconData icon;
    if (appState.favorites.contains(pair)) {
      icon = Icons.hot_tub;
    } else {
      icon = Icons.pool;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          BigCard(pair: pair),
          SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Favorite/like button
              ElevatedButton.icon(
                onPressed: () {
                  appState.toggleFavorite();
                },
                icon: Icon(
                  icon,
                  color: Colors.white,
                ),
                label: Text(
                  'Like',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  textStyle: TextStyle(color: Colors.white),
                  backgroundColor: Colors.orange,
                ),
              ),
              SizedBox(width: 10),
              // Next button
              ElevatedButton(
                onPressed: () {
                  appState.getNext();
                },
                style: ElevatedButton.styleFrom(
                  textStyle: TextStyle(color: Colors.white),
                  backgroundColor: Colors.orange,
                ),
                child: Text(
                  'Next',
                  style: TextStyle(color: Colors.white),
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
  const BigCard({
    Key? key,
    required this.pair,
  }) : super(key: key);

  final WordPair pair;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final style = theme.textTheme.displayMedium!.copyWith(
      color: Colors.white,
    );
    return Card(
      color: Color.fromRGBO(79, 75, 75, 1),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Text(
          pair.asLowerCase,
          style: style,
          semanticsLabel: "${pair.first} ${pair.second}",
        ),
      ),
    );
  }
}
