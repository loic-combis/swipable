import 'package:flutter/material.dart';
import 'package:flutter_swipable/flutter_swipable.dart';
import 'package:rxdart/rxdart.dart';

void main() {
  runApp(MyApp());
}

// Link to DB
final List data = [
  {
    'color': Colors.red,
  },
  {
    'color': Colors.green,
  },
  {
    'color': Colors.blue,
  }
];
BehaviorSubject<List<Card>> cards = BehaviorSubject.seeded([
  Card(
    data[0]['color'],
  ),
  Card(
    data[1]['color'],
  ),
  Card(
    data[2]['color'],
  ),
]);

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Dynamically load cards from database
  @override
  Widget build(BuildContext context) {
    // Stack of cards that can be swiped. Set width, height, etc here.
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
              onPressed: () {
                cards.add([
                  Card(
                    data[0]['color'],
                  ),
                  Card(
                    data[1]['color'],
                  ),
                  Card(
                    data[2]['color'],
                  ),
                ]);
                setState(() {});
              },
              icon: Icon(Icons.restore))
        ],
      ),
      body: Center(
        child: Container(
          alignment: Alignment.center,
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.7,
          // Important to keep as a stack to have overlay of cards.
          child: StreamBuilder<List<Card>>(
            stream: cards,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return SizedBox();
              final data = snapshot.data;
              return Stack(
                children: data!,
              );
            },
          ),
        ),
      ),
    );
  }
}

class Card extends StatelessWidget {
  // Made to distinguish cards
  // Add your own applicable data here
  final Color color;
  Card(this.color);

  @override
  Widget build(BuildContext context) {
    return Swipable(
      // Set the swipable widget
      verticalSwipe: false,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.0),
          color: color,
        ),
      ),
      onSwipeStart: (details) {},
      onSwipeCancel: (position, details) {},
      onSwipeEnd: (position, details) {},
      onPositionChanged: (details) {},
      onSwipeUp: (finalPosition) {
        print("Swipe Up");
      },
      onSwipeDown: (finalPosition) {
        print("Swipe Down");
      },
      onSwipeLeft: (finalPosition) {
        cards.add([
          ...cards.value,
          Card(
            data[0]['color'],
          ),
        ]);
        print("Swipe Left");
      },
      onSwipeRight: (finalPosition) {
        cards.add([
          ...cards.value,
          Card(
            data[0]['color'],
          ),
        ]);
        print("Swipe Right");
      },
      // onSwipeRight, left, up, down, cancel, etc...
    );
  }
}
